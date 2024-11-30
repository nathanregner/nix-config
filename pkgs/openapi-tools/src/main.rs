#![feature(associated_type_defaults)]

mod cli;
mod ext;
mod visitor;

use clap::Parser;
use cli::Cmd;
use core::{
    error::Error,
    iter::{IntoIterator, Iterator},
    option::Option::Some,
};
use ext::{ComponentRef, ComponentType, Method};
use indexmap::IndexMap;
use openapiv3::{Components, OpenAPI, Operation, PathItem, Paths, ReferenceOr};
use regex::Regex;
use std::{
    fs::{self},
    io::{self, Read, Write},
};
use visitor::{OperationPath, Visit, Visitor};

type Result<T> = std::result::Result<T, Box<dyn Error>>;

fn main() -> Result<()> {
    let args = cli::Args::parse();
    let Cmd::Filter(filter) = args.cmd;
    let input: Box<dyn Read> = match args.input {
        Some(input) => Box::new(io::BufReader::new(fs::File::open(input)?)),
        None => Box::new(io::stdin().lock()),
    };
    let schema = serde_json::from_reader::<_, openapiv3::OpenAPI>(input)?;
    let filtered = filter_schema(schema, filter);

    let output: Box<dyn Write> = match args.output {
        Some(input) => Box::new(io::BufWriter::new(fs::File::create(input)?)),
        None => Box::new(io::stdout()),
    };
    serde_json::to_writer_pretty(output, &filtered)?;
    Ok(())
}

fn any_match(set: &[Regex], haystack: &str) -> bool {
    set.iter().any(|r| r.is_match(haystack))
}

fn filter_schema(openapi: OpenAPI, filter: cli::Filter) -> OpenAPI {
    let components = openapi.components.unwrap_or_default();
    let mut visitor = ComponentRefVisitor {
        source: &components,
        components: Components {
            extensions: components.extensions.clone(),
            ..Default::default()
        },
        paths: Default::default(),
    };

    for (path, path_item) in &openapi.paths.paths {
        let ReferenceOr::Item(path_item) = path_item else {
            continue; // TODO: resolve ref?
        };
        for (method, operation) in Method::iter(path_item) {
            if any_match(&filter.path, &format!("{path}:{method}")) {
                visitor.visit_operation((path, method, operation));
                continue;
            }
            let Some(operation_id) = operation.operation_id.as_ref() else {
                continue;
            };
            if any_match(&filter.operation_id, &operation_id) {
                visitor.visit_operation((path, method, operation));
            }
        }
    }

    OpenAPI {
        components: Some(visitor.components),
        paths: Paths {
            extensions: openapi.paths.extensions,
            paths: visitor
                .paths
                .into_iter()
                .map(|(path, path_item)| (path, ReferenceOr::Item(path_item)))
                .collect(),
        },
        ..openapi
    }
}

struct ComponentRefVisitor<'s> {
    source: &'s Components,

    components: Components,
    paths: IndexMap<String, PathItem>,
}

impl<'s> Visitor<'s> for ComponentRefVisitor<'s> {
    fn visit_ref<T>(&mut self, r: &str) -> Option<ReferenceOr<T>> {
        let cr: ComponentRef = match r.parse() {
            Ok(r) => r,
            Err(err) => {
                eprintln!("Invalid ref {r}: {err}");
                return None;
            }
        };

        let Some(component) = ComponentRef::get(cr, &self.source) else {
            eprintln!("Component does not exist: {r}");
            return None;
        };

        if component.insert(&mut self.components) {
            match component.ty {
                ComponentType::Schema(c) => {
                    Visit::visit(c, self)?;
                }
                ComponentType::Response(c) => {
                    Visit::visit(c, self)?;
                }
                ComponentType::Parameter(c) => {
                    Visit::visit(c, self)?;
                }
                ComponentType::RequestBody(c) => {
                    Visit::visit(c, self)?;
                }
            };
        }

        return Some(ReferenceOr::ref_(r));
    }

    fn visit_operation<'o: 's>(
        &mut self,
        (path, method, operation): OperationPath<'o>,
    ) -> Option<Operation> {
        visitor::visit_operation(self, (path, method, operation));
        let path = self
            .paths
            .entry(path.to_string())
            .or_insert_with(PathItem::default);
        // *method.get_mut(path) = Some(operation.clone());
        Some(operation.clone())
    }
}
