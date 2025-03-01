use openapiv3::{
    AdditionalProperties, ArrayType, Content, MediaType, ObjectType, Operation, Parameter,
    ParameterSchemaOrContent, PathItem, ReferenceOr, RequestBody, Response, Schema, SchemaKind,
    Type,
};

use crate::ext::Method;

pub trait Visit<'s> {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>);
}

impl<'s> Visit<'s> for Schema {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_schema(self)
    }
}

impl<'s> Visit<'s> for Box<Schema> {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        Schema::visit(self, visitor)
    }
}

impl<'s> Visit<'s> for ObjectType {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_object_type(self)
    }
}

impl<'s> Visit<'s> for ArrayType {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_array_type(self)
    }
}

pub type Path<'a, 'b> = (&'a str, &'b mut PathItem);

impl<'s> Visit<'s> for Path<'s, 's> {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_path(self.0, self.1)
    }
}

impl<'s, T> Visit<'s> for ReferenceOr<T>
where
    T: Visit<'s>,
{
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        match self {
            ReferenceOr::Reference { reference } => visitor.visit_ref(reference),
            ReferenceOr::Item(item) => item.visit(visitor),
        }
    }
}

impl<'s> Visit<'s> for Content {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        for (name, media_type) in self.iter_mut() {
            (name.as_str(), media_type).visit(visitor);
        }
    }
}

impl<'v, 's> Visit<'v> for (&'s str, &'s mut MediaType) {
    fn visit(&mut self, visitor: &mut impl Visitor<'v>) {
        visitor.visit_media_type(self.0, self.1)
    }
}

impl<'s> Visit<'s> for Parameter {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_parameter(self)
    }
}

impl<'s> Visit<'s> for RequestBody {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_request_body(self)
    }
}

impl<'s> Visit<'s> for Response {
    fn visit(&mut self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_response(self)
    }
}

pub trait Visitor<'s>: Sized {
    fn visit_path(&mut self, path: &str, path_item: &mut PathItem) {
        for parameter in path_item.parameters.iter_mut() {
            parameter.visit(self)
        }

        use Method::*;
        for method in [Get, Put, Post, Delete, Options, Head, Patch, Trace] {
            if let Some(operation) = method.get_mut(path_item) {
                self.visit_operation(path, method, operation);
            }
        }
    }

    fn visit_schema(&mut self, schema: &mut Schema) {
        match &mut schema.schema_kind {
            SchemaKind::Type(t) => match t {
                Type::Object(object) => self.visit_object_type(object),
                Type::Array(array) => self.visit_array_type(array),
                Type::String(_) | Type::Number(_) | Type::Integer(_) | Type::Boolean(_) => {}
            },
            SchemaKind::OneOf { one_of: schemas }
            | SchemaKind::AllOf { all_of: schemas }
            | SchemaKind::AnyOf { any_of: schemas } => {
                for schema in schemas {
                    schema.visit(self)
                }
            }
            SchemaKind::Not { not } => not.visit(self),
            SchemaKind::Any(_) => {}
        }
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
        let parameter = match parameter {
            Parameter::Query { parameter_data, .. }
            | Parameter::Header { parameter_data, .. }
            | Parameter::Path { parameter_data, .. }
            | Parameter::Cookie { parameter_data, .. } => parameter_data,
        };
        match &mut parameter.format {
            ParameterSchemaOrContent::Schema(schema) => schema.visit(self),
            ParameterSchemaOrContent::Content(content) => content.visit(self),
        }
    }

    fn visit_response(&mut self, response: &mut Response) {
        response.content.visit(self);
    }

    fn visit_request_body(&mut self, request_body: &mut RequestBody) {
        request_body.content.visit(self)
    }

    fn visit_media_type(&mut self, _name: &str, media_type: &mut MediaType) {
        if let MediaType {
            schema: Some(schema),
            ..
        } = media_type
        {
            schema.visit(self)
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
}
