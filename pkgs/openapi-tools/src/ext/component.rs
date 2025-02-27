use core::str::FromStr;
use enum_map::Enum;
use indexmap::IndexMap;
use strum::EnumString;

use color_eyre::eyre;
use openapiv3::{
    Callback, Components, Example, Header, Link, Parameter, ReferenceOr, RequestBody, Response,
    Schema, SecurityScheme,
};

use crate::visitor::Visit;

#[derive(Enum, Hash, Eq, PartialEq, Copy, Clone, Debug, EnumString)]
pub enum ComponentType {
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
    pub ty: ComponentType,
    pub name: String,
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

pub trait Component: Visit + Sized {
    const TYPE: ComponentType;

    fn get_in_mut(components: &mut Components) -> &mut IndexMap<String, ReferenceOr<Self>>;
}

macro_rules! impl_component {
    ($ty:ty, $variant:ident, $field:ident) => {
        impl Component for $ty {
            const TYPE: ComponentType = ComponentType::$variant;

            fn get_in_mut(components: &mut Components) -> &mut IndexMap<String, ReferenceOr<Self>> {
                &mut components.$field
            }
        }
    };
}

impl_component!(Schema, Schemas, schemas);
impl_component!(RequestBody, RequestBodies, request_bodies);
impl_component!(Parameter, Parameters, parameters);
impl_component!(Response, Responses, responses);
impl_component!(Example, Examples, examples);
impl_component!(Header, Headers, headers);
impl_component!(SecurityScheme, SecuritySchemes, security_schemes);
impl_component!(Link, Links, links);
impl_component!(Callback, Callbacks, callbacks);
