use indexmap::IndexMap;
use openapiv3::{
    AdditionalProperties, ArrayType, Callback, Components, Content, Example, Header, Link,
    MediaType, ObjectType, OpenAPI, Operation, Parameter, ParameterSchemaOrContent, PathItem,
    Paths, ReferenceOr, RequestBody, Response, Schema, SchemaKind, SecurityScheme, Type,
};

use crate::ext::{Component, Method};

pub trait Visit {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>);
}

impl Visit for Paths {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_paths(self)
    }
}

impl Visit for Schema {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_schema(self)
    }
}

impl Visit for Box<Schema> {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_schema(self)
    }
}

impl Visit for Example {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_example(self)
    }
}

impl Visit for Header {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_header(self)
    }
}

impl Visit for SecurityScheme {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_security_scheme(self)
    }
}

impl Visit for Link {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_link(self)
    }
}

impl Visit for Callback {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_callback(self)
    }
}

impl Visit for ObjectType {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_object_type(self)
    }
}

impl Visit for ArrayType {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_array_type(self)
    }
}

pub type Path<'a, 'b> = (&'a str, &'b mut PathItem);

impl Visit for Path<'_, '_> {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_path(self.0, self.1)
    }
}

impl<T> Visit for ReferenceOr<T>
where
    T: Visit,
{
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        match self {
            ReferenceOr::Reference { reference } => visitor.visit_ref(reference),
            ReferenceOr::Item(item) => item.visit(visitor),
        }
    }
}

impl Visit for Content {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        for (name, media_type) in self.iter_mut() {
            (name.as_str(), media_type).visit(visitor);
        }
    }
}

impl Visit for (&str, &mut MediaType) {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_media_type(self.0, self.1)
    }
}

impl Visit for Parameter {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_parameter(self)
    }
}

impl Visit for RequestBody {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_request_body(self)
    }
}

impl Visit for Response {
    fn visit<'s>(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_response(self)
    }
}

pub trait Visitor<'s>: Sized {
    fn visit_api(&mut self, api: &mut OpenAPI);

    fn visit_paths(&mut self, paths: &mut Paths) {
        visit_paths(self, paths)
    }

    fn visit_path(&mut self, path: &str, path_item: &mut PathItem) {
        visit_path(self, path, path_item);
    }

    fn visit_all_components(&mut self, components: &mut Components) {
        fn visit<'s, 'c, C: Component>(
            visitor: &mut impl Visitor<'s>,
            components: &'c mut Components,
        ) {
            visitor.visit_components(C::get_in_mut(components))
        }
        visit::<Schema>(self, components);
        visit::<RequestBody>(self, components);
        visit::<Parameter>(self, components);
        visit::<Response>(self, components);
        visit::<Example>(self, components);
        visit::<Header>(self, components);
        visit::<SecurityScheme>(self, components);
        visit::<Link>(self, components);
        visit::<Callback>(self, components);
    }

    fn visit_components<C: Component>(
        &mut self,
        components: &mut IndexMap<String, ReferenceOr<C>>,
    ) {
        for (_name, component) in components {
            component.visit(self);
        }
    }

    fn visit_schema(&mut self, schema: &mut Schema) {
        visit_schema(self, schema);
    }

    fn visit_example(&mut self, example: &mut Example) {
        let _ = example;
    }

    fn visit_header(&mut self, header: &mut Header) {
        visit_header(self, header);
    }

    fn visit_security_scheme(&mut self, security_scheme: &mut SecurityScheme) {
        let _ = security_scheme;
    }

    fn visit_callback(&mut self, callback: &mut Callback) {
        for (path, path_item) in callback.iter_mut() {
            visit_path(self, path, path_item);
        }
    }

    fn visit_link(&mut self, link: &mut Link) {
        let _ = link; // TODO: default implementation (link.operation)
        tracing::warn!("visit_link not implemented, skipping: {link:?}")
    }

    fn visit_ref(&mut self, reference: &str);

    fn visit_object_type(&mut self, schema: &mut ObjectType) {
        for (_, property) in schema.properties.iter_mut() {
            property.visit(self)
        }
        if let Some(AdditionalProperties::Schema(additional_properties)) =
            &mut schema.additional_properties
        {
            additional_properties.visit(self)
        }
    }

    fn visit_array_type(&mut self, schema: &mut ArrayType) {
        if let Some(items) = &mut schema.items {
            items.visit(self)
        }
    }

    fn visit_operation(&mut self, path: &str, method: Method, operation: &mut Operation) {
        visit_operation(self, path, method, operation)
    }

    fn visit_parameter(&mut self, parameter: &mut Parameter) {
        visit_parameter(self, parameter);
    }

    fn visit_response(&mut self, response: &mut Response) {
        response.content.visit(self);
    }

    fn visit_request_body(&mut self, request_body: &mut RequestBody) {
        request_body.content.visit(self)
    }

    fn visit_media_type(&mut self, _name: &str, media_type: &mut MediaType) {
        visit_media_type(self, media_type);
    }
}

fn visit_header<'s>(visitor: &mut impl Visitor<'s>, header: &mut Header) {
    match &mut header.format {
        ParameterSchemaOrContent::Schema(reference_or) => reference_or.visit(visitor),
        ParameterSchemaOrContent::Content(media_types) => {
            for (name, media_type) in media_types.iter_mut() {
                (name.as_str(), media_type).visit(visitor);
            }
        }
    }
    visit_examples(visitor, &mut header.examples);
}

fn visit_media_type<'s>(visitor: &mut impl Visitor<'s>, media_type: &mut MediaType) {
    if let MediaType {
        schema: Some(schema),
        ..
    } = media_type
    {
        schema.visit(visitor)
    }
    visit_examples(visitor, &mut media_type.examples);
}

fn visit_examples<'s>(
    visitor: &mut impl Visitor<'s>,
    examples: &mut IndexMap<String, ReferenceOr<Example>>,
) {
    for (_, example) in examples {
        example.visit(visitor);
    }
}

fn visit_path<'s>(visitor: &mut impl Visitor<'s>, path: &str, path_item: &mut PathItem) {
    for parameter in path_item.parameters.iter_mut() {
        parameter.visit(visitor)
    }

    use Method::*;
    for method in [Get, Put, Post, Delete, Options, Head, Patch, Trace] {
        if let Some(operation) = method.get_mut(path_item) {
            visitor.visit_operation(path, method, operation);
        }
    }
}

fn visit_schema<'s>(visitor: &mut impl Visitor<'s>, schema: &mut Schema) {
    match &mut schema.schema_kind {
        SchemaKind::Type(t) => match t {
            Type::Object(object) => visitor.visit_object_type(object),
            Type::Array(array) => visitor.visit_array_type(array),
            Type::String(_) | Type::Number(_) | Type::Integer(_) | Type::Boolean(_) => {}
        },
        SchemaKind::OneOf { one_of: schemas }
        | SchemaKind::AllOf { all_of: schemas }
        | SchemaKind::AnyOf { any_of: schemas } => {
            for schema in schemas {
                schema.visit(visitor)
            }
        }
        SchemaKind::Not { not } => not.visit(visitor),
        SchemaKind::Any(_) => {}
    }
}

fn visit_parameter<'s>(visitor: &mut impl Visitor<'s>, parameter: &mut Parameter) {
    let parameter = match parameter {
        Parameter::Query { parameter_data, .. }
        | Parameter::Header { parameter_data, .. }
        | Parameter::Path { parameter_data, .. }
        | Parameter::Cookie { parameter_data, .. } => parameter_data,
    };
    match &mut parameter.format {
        ParameterSchemaOrContent::Schema(schema) => schema.visit(visitor),
        ParameterSchemaOrContent::Content(content) => content.visit(visitor),
    }
    visit_examples(visitor, &mut parameter.examples);
}

pub fn visit_paths<'s>(visitor: &mut impl Visitor<'s>, paths: &mut Paths) {
    for (path, path_item) in paths.paths.iter_mut() {
        let path_item = match path_item {
            ReferenceOr::Item(path_item) => path_item,
            ReferenceOr::Reference { reference } => {
                visitor.visit_ref(reference);
                continue;
            }
        };
        for (method, operation) in Method::iter_mut(path_item) {
            if let Some(operation) = operation {
                visitor.visit_operation(path, method, operation);
            }
        }
    }
}

pub fn visit_operation<'s>(
    visitor: &mut impl Visitor<'s>,
    _path: &str,
    _method: Method,
    operation: &mut Operation,
) {
    for parameter in &mut operation.parameters {
        parameter.visit(visitor)
    }
    if let Some(body) = &mut operation.request_body {
        body.visit(visitor)
    }
    if let Some(response) = &mut operation.responses.default {
        response.visit(visitor)
    }
    for (_, response) in &mut operation.responses.responses {
        response.visit(visitor)
    }
    for (_, callback) in &mut operation.callbacks {
        callback.visit(visitor);
    }
}
