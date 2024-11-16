use core::{fmt::Display, str::FromStr};
use indexmap::IndexMap;
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
    pub fn iter(path: &PathItem) -> impl Iterator<Item = (Method, &Operation)> {
        [
            (Method::Get, path.get.as_ref()),
            (Method::Put, path.put.as_ref()),
            (Method::Post, path.post.as_ref()),
            (Method::Delete, path.delete.as_ref()),
            (Method::Options, path.options.as_ref()),
            (Method::Head, path.head.as_ref()),
            (Method::Patch, path.patch.as_ref()),
            (Method::Trace, path.trace.as_ref()),
        ]
        .into_iter()
        .filter_map(|(method, operation)| Some((method, operation?)))
    }

    pub fn get(self, path: &PathItem) -> Option<&Operation> {
        match self {
            Method::Get => path.get.as_ref(),
            Method::Put => path.put.as_ref(),
            Method::Post => path.post.as_ref(),
            Method::Delete => path.delete.as_ref(),
            Method::Options => path.options.as_ref(),
            Method::Head => path.head.as_ref(),
            Method::Patch => path.patch.as_ref(),
            Method::Trace => path.trace.as_ref(),
        }
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
    pub fn get<'s>(
        ComponentRef { ty, name }: Self,
        components: &'s Components,
    ) -> Option<Component<'s>> {
        let ty = match ty {
            ComponentRefType::Schemas => ComponentType::Schema(components.schemas.get(&name)?),
            ComponentRefType::Responses => {
                ComponentType::Response(components.responses.get(&name)?)
            }
            ComponentRefType::Parameters => {
                ComponentType::Parameter(components.parameters.get(&name)?)
            }
            ComponentRefType::RequestBodies => {
                ComponentType::RequestBody(components.request_bodies.get(&name)?)
            }
            _ => return None,
        };
        Some(Component { ty, name })
    }
}

#[derive(Clone, Debug)]
pub struct Component<'s> {
    pub name: String,
    pub ty: ComponentType<'s>,
}

impl<'s> Component<'s> {
    pub fn insert(&self, components: &mut Components) -> bool {
        fn insert<T: Clone>(
            components: &mut IndexMap<String, T>,
            name: &str,
            component: &T,
        ) -> bool {
            if components.contains_key(name) {
                return false;
            }
            components.insert(name.to_string(), component.clone());
            true
        }

        match self.ty {
            ComponentType::Schema(schema) => insert(&mut components.schemas, &self.name, schema),
            ComponentType::Response(response) => {
                insert(&mut components.responses, &self.name, response)
            }
            ComponentType::Parameter(parameter) => {
                insert(&mut components.parameters, &self.name, parameter)
            }
            ComponentType::RequestBody(request_body) => {
                insert(&mut components.request_bodies, &self.name, request_body)
            }
        }
    }
}

#[derive(Copy, Clone, Debug)]
pub enum ComponentType<'s> {
    Schema(&'s ReferenceOr<Schema>),
    Response(&'s ReferenceOr<Response>),
    Parameter(&'s ReferenceOr<Parameter>),
    // Example,
    RequestBody(&'s ReferenceOr<RequestBody>),
    // Header,
    // SecurityScheme,
    // Link,
    // Callback,
    // Extension,
}

impl<'s> From<ComponentType<'s>> for ComponentRefType {
    fn from(ty: ComponentType<'s>) -> Self {
        match ty {
            ComponentType::Schema(_) => Self::Schemas,
            ComponentType::Response(_) => Self::Responses,
            ComponentType::Parameter(_) => Self::Parameters,
            ComponentType::RequestBody(_) => Self::RequestBodies,
        }
    }
}
