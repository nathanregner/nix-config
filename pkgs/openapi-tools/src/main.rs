#![feature(let_chains)]

mod cli;
mod ext;
mod visitor;

use clap::Parser;
use cli::{Cmd, Filter};
use core::{error::Error, iter::Iterator, option::Option::Some};
use ext::{ComponentRef, Method};
use indexmap::IndexMap;
use openapiv3::{Components, OpenAPI, PathItem, Paths, ReferenceOr};
use regex::Regex;
use std::{
    collections::HashSet,
    fs::{self},
    io::{self, Read, Write},
};
use visitor::{visit_paths, Visitor};

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

fn filter_schema(mut open_api: OpenAPI, filter: cli::Filter) -> OpenAPI {
    let mut visitor = ComponentRefVisitor {
        filter,
        visited: HashSet::default(),
        paths: Default::default(),
    };

    visitor.visit_paths(&mut open_api.paths);
    // if let Some(components) = &mut open_api.components {
    //     components.extensions
    // }
    open_api
}

struct ComponentRefVisitor {
    filter: Filter, // TODO: just take 2 fields
    visited: HashSet<ComponentRef>,
    paths: IndexMap<String, PathItem>,
}

impl<'s> Visitor<'s> for ComponentRefVisitor<'s> {
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
                    && any_match(&self.filter.operation_id, &operation_id)
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
        self.visited.insert(cr);
    }
}
