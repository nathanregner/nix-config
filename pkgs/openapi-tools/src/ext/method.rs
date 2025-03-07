use core::fmt::Display;

use openapiv3::{Operation, PathItem};

#[derive(Hash, Eq, PartialEq, Copy, Clone, Debug)]
pub enum Method {
    Get,
    Put,
    Post,
    Delete,
    Options,
    Head,
    Patch,
    Trace,
}

impl Display for Method {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        f.write_str(match self {
            Method::Get => "GET",
            Method::Put => "PUT",
            Method::Post => "POST",
            Method::Delete => "DELETE",
            Method::Options => "OPTIONS",
            Method::Head => "HEAD",
            Method::Patch => "PATCH",
            Method::Trace => "TRACE",
        })
    }
}

impl Method {
    pub fn iter_mut(path: &mut PathItem) -> impl Iterator<Item = (Method, &mut Option<Operation>)> {
        [
            (Method::Get, &mut path.get),
            (Method::Put, &mut path.put),
            (Method::Post, &mut path.post),
            (Method::Delete, &mut path.delete),
            (Method::Options, &mut path.options),
            (Method::Head, &mut path.head),
            (Method::Patch, &mut path.patch),
            (Method::Trace, &mut path.trace),
        ]
        .into_iter()
    }

    pub fn get_mut(self, path: &mut PathItem) -> &mut Option<Operation> {
        match self {
            Method::Get => &mut path.get,
            Method::Put => &mut path.put,
            Method::Post => &mut path.post,
            Method::Delete => &mut path.delete,
            Method::Options => &mut path.options,
            Method::Head => &mut path.head,
            Method::Patch => &mut path.patch,
            Method::Trace => &mut path.trace,
        }
    }
}
