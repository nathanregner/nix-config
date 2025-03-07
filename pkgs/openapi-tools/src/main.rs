#![feature(let_chains)]

mod cli;
mod ext;
mod visitor;

use clap::Parser;
use cli::{Cmd, Filter};
use core::{error::Error, iter::Iterator, option::Option::Some};
use enum_map::EnumMap;
use ext::{Component, ComponentRef, ComponentType, Method};
use openapiv3::{
    Callback, Components, Example, Header, Link, OpenAPI, Parameter, Paths, ReferenceOr,
    RequestBody, Response, Schema, SecurityScheme,
};
use regex::Regex;
use std::{
    collections::HashSet,
    fs::{self},
    io::{self, Read, Write},
};
use visitor::{visit_paths, Visit, Visitor};

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

fn filter_schema(mut api: OpenAPI, filter: cli::Filter) -> OpenAPI {
    let mut visitor = ComponentRefVisitor {
        filter,
        visiting: vec![],
        visited: EnumMap::default(),
    };

    visitor.visit_api(&mut api);
    api
}

struct ComponentRefVisitor {
    filter: Filter,
    visiting: Vec<ComponentRef>,
    visited: EnumMap<ComponentType, HashSet<String>>,
}

impl Visitor<'_> for ComponentRefVisitor {
    fn visit_api(&mut self, api: &mut OpenAPI) {
        self.visit_paths(&mut api.paths);

        if let Some(components) = &mut api.components {
            while let Some(cr) = self.visiting.pop() {
                match cr.ty {
                    ComponentType::Schemas => self.expand_ref::<Schema>(components, &cr.name),
                    ComponentType::Responses => self.expand_ref::<Response>(components, &cr.name),
                    ComponentType::Parameters => self.expand_ref::<Parameter>(components, &cr.name),
                    ComponentType::Examples => self.expand_ref::<Example>(components, &cr.name),
                    ComponentType::RequestBodies => {
                        self.expand_ref::<Response>(components, &cr.name)
                    }
                    ComponentType::Headers => self.expand_ref::<Header>(components, &cr.name),
                    ComponentType::SecuritySchemes => {
                        self.expand_ref::<SecurityScheme>(components, &cr.name)
                    }
                    ComponentType::Links => self.expand_ref::<Link>(components, &cr.name),
                    ComponentType::Callbacks => self.expand_ref::<Callback>(components, &cr.name),
                    ComponentType::Extensions => {
                        // TODO
                    } // ComponentType::Extensions => self.expand_ref::<Extension>(components, &cr.name),
                }
            }

            self.visit_components(components);
        }
    }

    fn visit_paths(&mut self, paths: &mut Paths) {
        // filter operations
        paths.paths.retain(|path, path_item| {
            let ReferenceOr::Item(path_item) = path_item else {
                return false; // resolve ref?
            };

            for (method, method_op) in Method::iter_mut(path_item) {
                let Some(op) = method_op else {
                    continue;
                };

                if any_match(&self.filter.path, &format!("{path}:{method}")) {
                    continue;
                }

                if let Some(operation_id) = &op.operation_id
                    && any_match(&self.filter.operation_id, operation_id)
                {
                    continue;
                }

                *method_op = None;
            }

            Method::iter_mut(path_item).any(|(_, method_op)| method_op.is_some())
        });

        // filter components
        visit_paths(self, paths)
    }

    fn visit_ref(&mut self, r: &str) {
        let cr: ComponentRef = match r.parse() {
            Ok(r) => r,
            Err(err) => {
                eprintln!("Invalid ref {r}: {err}");
                return;
            }
        };
        if self.visited[cr.ty].insert(cr.name.clone()) {
            self.visiting.push(cr);
        }
    }

    fn visit_components(&mut self, components: &mut Components) {
        self.retain::<Schema>(components);
        self.retain::<RequestBody>(components);
        self.retain::<Parameter>(components);
        self.retain::<Response>(components);
        self.retain::<Example>(components);
        self.retain::<Header>(components);
        self.retain::<SecurityScheme>(components);
        self.retain::<Link>(components);
        self.retain::<Callback>(components);
    }
}

impl ComponentRefVisitor {
    fn retain<T: Component>(&mut self, components: &mut Components) {
        T::get_in_mut(components).retain(|name, _| self.visited[T::COMPONENT_TYPE].contains(name));
    }

    fn expand_ref<'s, T>(&mut self, components: &mut Components, name: &str)
    where
        T: Component + Visit<'s>,
    {
        let components_of_type = T::get_in_mut(components);
        if let Some(component) = components_of_type.get_mut(name) {
            component.visit(self)
        }
    }
}
