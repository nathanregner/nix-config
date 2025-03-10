use std::path::PathBuf;

use clap::{Parser, Subcommand};
use regex::Regex;

#[derive(Parser, Debug)]
#[command()]
pub struct Args {
    #[arg(short, long)]
    pub input: Option<PathBuf>,
    #[arg(short, long)]
    pub output: Option<PathBuf>,
    #[command(subcommand)]
    pub cmd: Cmd,
}

#[derive(Subcommand, Debug)]
pub enum Cmd {
    Filter(Filter),
}

#[derive(Parser, Debug)]
pub struct Filter {
    /// Regex to match against operation name
    #[arg(short, long)]
    pub operation_id: Vec<Regex>,
    /// Regex to match against `/path/segment:METHOD`
    #[arg(short, long)]
    pub path: Vec<Regex>,
    // TODO /// Regex to match against request/response media types
    #[arg(short, long)]
    pub media_type: Vec<Regex>,
}
