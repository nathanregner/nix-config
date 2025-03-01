use core::{fmt::Display, str::FromStr};
use strum::EnumString;

use color_eyre::eyre;
use openapiv3::{
    Components, Operation, Parameter, PathItem, ReferenceOr, RequestBody, Response, Schema,
};

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
    pub fn iter_mut(path: &mut PathItem) -> impl Iterator<Item = (Method, &mut Operation)> {
        [
            (Method::Get, path.get.as_mut()),
            (Method::Put, path.put.as_mut()),
            (Method::Post, path.post.as_mut()),
            (Method::Delete, path.delete.as_mut()),
            (Method::Options, path.options.as_mut()),
            (Method::Head, path.head.as_mut()),
            (Method::Patch, path.patch.as_mut()),
            (Method::Trace, path.trace.as_mut()),
        ]
        .into_iter()
        .filter_map(|(method, operation)| Some((method, operation?)))
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

#[derive(Hash, Eq, PartialEq, Clone, Debug, EnumString)]
pub enum ComponentRefType {
    #[strum(serialize = "schemas")]
    Schemas,
    #[strum(serialize = "responses")]
    Responses,
    #[strum(serialize = "parameters")]
    Parameters,
    #[strum(serialize = "examples")]
    Examples,
    #[strum(serialize = "request_bodies")]
    RequestBodies,
    #[strum(serialize = "headers")]
    Headers,
    #[strum(serialize = "security_schemes")]
    SecuritySchemes,
    #[strum(serialize = "links")]
    Links,
    #[strum(serialize = "callbacks")]
    Callbacks,
    #[strum(serialize = "extensions")]
    Extensions,
}

#[derive(Hash, Eq, PartialEq, Clone, Debug)]
pub struct ComponentRef {
    ty: ComponentRefType,
    name: String,
}

impl FromStr for ComponentRef {
    type Err = eyre::Report;

    fn from_str(s: &str) -> core::result::Result<Self, Self::Err> {
        let prefix = "#/components/";
        let Some(ty_name) = s.strip_prefix(prefix) else {
            eyre::bail!("Invalid ref: {s}");
        };

        let (ty, name) = ty_name
            .split_once("/")
            .ok_or_else(|| eyre::eyre!("Invalid ref: {s}"))?;

        let ty = ty.parse()?;

        Ok(ComponentRef {
            ty,
            name: name.to_string(),
        })
    }
}

impl ComponentRef {
    pub fn get(ComponentRef { ty, name }: Self, components: &Components) -> Option<Component> {
        let ty = match ty {
            ComponentRefType::Schemas => {
                ComponentType::Schema(components.schemas.get(&name)?.clone())
            }
            ComponentRefType::Responses => {
                ComponentType::Response(components.responses.get(&name)?.clone())
            }
            ComponentRefType::Parameters => {
                ComponentType::Parameter(components.parameters.get(&name)?.clone())
            }
            ComponentRefType::RequestBodies => {
                ComponentType::RequestBody(components.request_bodies.get(&name)?.clone())
            }
            _ => return None,
        };
        Some(Component { ty, name })
    }
}

#[derive(Clone, Debug)]
pub struct Component {
    pub name: String,
    pub ty: ComponentType,
}

#[derive(Clone, Debug)]
pub enum ComponentType {
    Schema(ReferenceOr<Schema>),
    Response(ReferenceOr<Response>),
    Parameter(ReferenceOr<Parameter>),
    // Example,
    RequestBody(ReferenceOr<RequestBody>),
    // Header,
    // SecurityScheme,
    // Link,
    // Callback,
    // Extension,
}

impl From<ComponentType> for ComponentRefType {
    fn from(ty: ComponentType) -> Self {
        match ty {
            ComponentType::Schema(_) => Self::Schemas,
            ComponentType::Response(_) => Self::Responses,
            ComponentType::Parameter(_) => Self::Parameters,
            ComponentType::RequestBody(_) => Self::RequestBodies,
        }
    }
}
