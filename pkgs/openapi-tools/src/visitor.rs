use openapiv3::{
    AdditionalProperties, ArrayType, MediaType, ObjectType, Operation, Parameter,
    ParameterSchemaOrContent, PathItem, ReferenceOr, RequestBody, Response, Schema, SchemaKind,
    Type,
};

use crate::ext::Method;

pub trait Visit<'s> {
    fn visit(&self, visitor: &mut impl Visitor<'s>);
}

impl<'s> Visit<'s> for Schema {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_schema(&self)
    }
}

impl<'s> Visit<'s> for Box<Schema> {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        Schema::visit(self, visitor)
    }
}

impl<'s> Visit<'s> for ObjectType {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_object_type(&self)
    }
}

impl<'s> Visit<'s> for ArrayType {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_array_type(self)
    }
}

pub type Path<'s> = (&'s str, &'s PathItem);

impl<'s> Visit<'s> for Path<'s> {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_path(*self)
    }
}

pub type OperationPath<'s> = (&'s str, Method, &'s Operation);

impl<'s> Visit<'s> for OperationPath<'s> {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_operation(*self)
    }
}

impl<'s, T> Visit<'s> for ReferenceOr<T>
where
    T: Visit<'s>,
{
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        match self {
            ReferenceOr::Reference { reference } => visitor.visit_ref(reference),
            ReferenceOr::Item(item) => item.visit(visitor),
        }
    }
}

impl<'s> Visit<'s> for MediaType {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_media_type(self)
    }
}

impl<'s> Visit<'s> for Parameter {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_parameter(self)
    }
}

impl<'s> Visit<'s> for RequestBody {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_request_body(self)
    }
}

impl<'s> Visit<'s> for Response {
    fn visit(&self, visitor: &mut impl Visitor<'s>) {
        visitor.visit_response(self)
    }
}

pub trait Visitor<'s>: Sized {
    fn visit_path(&mut self, (path, path_item): Path<'s>) {
        for parameter in &path_item.parameters {
            parameter.visit(self)
        }

        macro_rules! visit_methods {
            ($($method: ident),+) => {
                $({
                let method = Method::$method;
                if let Some(operation) = method.get(&path_item) {
                    (path, method, operation).visit(self);
                }
                })+
            };
        }

        visit_methods!(Get, Put, Post, Delete, Options, Head, Patch, Trace);
    }

    fn visit_schema(&mut self, schema: &Schema) {
        match &schema.schema_kind {
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

    fn visit_object_type(&mut self, schema: &ObjectType) {
        for (_, property) in &schema.properties {
            property.visit(self)
        }
        if let Some(AdditionalProperties::Schema(additional_properties)) =
            &schema.additional_properties
        {
            (**additional_properties).visit(self)
        }
    }

    fn visit_array_type(&mut self, schema: &ArrayType) {
        if let Some(items) = &schema.items {
            items.visit(self)
        }
    }

    fn visit_operation<'o: 's>(&mut self, operation: OperationPath<'o>) {
        visit_operation(self, operation)
    }

    fn visit_parameter(&mut self, parameter: &Parameter) {
        let parameter = match parameter {
            Parameter::Query { parameter_data, .. }
            | Parameter::Header { parameter_data, .. }
            | Parameter::Path { parameter_data, .. }
            | Parameter::Cookie { parameter_data, .. } => parameter_data,
        };
        if let ParameterSchemaOrContent::Schema(schema) = &parameter.format {
            schema.visit(self)
        }
    }

    fn visit_response(&mut self, response: &Response) {
        for (_, media_type) in &response.content {
            media_type.visit(self)
        }
    }

    fn visit_request_body(&mut self, request_body: &RequestBody) {
        for (_, media_type) in &request_body.content {
            media_type.visit(self)
        }
    }

    fn visit_media_type(&mut self, media_type: &MediaType) {
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
    (_path, _method, operation): OperationPath,
) {
    for parameter in &operation.parameters {
        parameter.visit(visitor)
    }
    if let Some(body) = &operation.request_body {
        body.visit(visitor)
    }
    if let Some(response) = &operation.responses.default {
        response.visit(visitor)
    }
    for (_, response) in &operation.responses.responses {
        response.visit(visitor)
    }
}
