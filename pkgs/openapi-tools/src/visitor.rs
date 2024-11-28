use openapiv3::{
    AdditionalProperties, ArrayType, MediaType, ObjectType, Operation, Parameter,
    ParameterSchemaOrContent, PathItem, ReferenceOr, RequestBody, Response, Responses, Schema,
    SchemaKind, Type,
};

use crate::ext::Method;

pub trait Visit<'s>: Sized {
    type Output = Option<Self>;

    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output;
}

impl<'s> Visit<'s> for Schema {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_schema(&self)
    }
}

impl<'s> Visit<'s> for Box<Schema> {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        Box::new(Schema::visit(self, visitor))
    }
}

impl<'s> Visit<'s> for ObjectType {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_object_type(&self)
    }
}

impl<'s> Visit<'s> for ArrayType {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_array_type(self)
    }
}

pub type Path<'s> = (&'s str, &'s PathItem);

impl<'s> Visit<'s> for Path<'s> {
    type Output = Option<PathItem>;

    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_path(*self)
    }
}

pub type OperationPath<'s> = (&'s str, Method, &'s Operation);

impl<'s> Visit<'s> for OperationPath<'s> {
    type Output = Option<Operation>;

    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_operation(*self)
    }
}

impl<'s, T> Visit<'s> for ReferenceOr<T>
where
    T: Visit<'s, Output = Option<T>>,
{
    type Output = Option<ReferenceOr<T>>;

    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        match self {
            ReferenceOr::Reference { reference } => visitor.visit_ref(reference),
            ReferenceOr::Item(item) => Some(ReferenceOr::Item(item.visit(visitor)?)),
        }
    }
}

impl<'s> Visit<'s> for MediaType {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_media_type(self)
    }
}

impl<'s> Visit<'s> for Parameter {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_parameter(self)
    }
}

impl<'s> Visit<'s> for RequestBody {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_request_body(self)
    }
}

impl<'s> Visit<'s> for Response {
    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_response(self)
    }
}

pub trait Visitor<'s>: Sized {
    fn visit_path(&mut self, (path, path_item): Path<'s>) -> Option<PathItem> {
        let mut result = PathItem {
            parameters: path_item
                .parameters
                .iter()
                .filter_map(|parameter| parameter.visit(self))
                .collect(),
            ..path_item.clone()
        };

        macro_rules! visit_methods {
            ($($method: ident),+) => {
                $({
                let method = Method::$method;
                if let Some(operation) = method.get(&path_item) {
                    let operation = (path, method, operation).visit(self);
                    *method.get_mut(&mut result) = operation;
                }
                })+
            };
        }

        visit_methods!(Get, Put, Post, Delete, Options, Head, Patch, Trace);

        Some(result)
    }

    fn visit_schema(&mut self, schema: &Schema) -> Option<Schema> {
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

    fn visit_ref<T>(&mut self, reference: &str) -> Option<ReferenceOr<T>>;

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

    fn visit_operation<'o: 's>(&mut self, operation: OperationPath<'o>) -> Option<Operation> {
        Some(visit_operation(self, operation))
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

    fn visit_response(&mut self, response: &Response) -> Option<Response> {
        Some(Response {
            content: response
                .content
                .iter()
                .filter_map(|(name, media_type)| Some((name.to_string(), media_type.visit(self)?)))
                .collect(),
            ..response.clone()
        })
    }

    fn visit_request_body(&mut self, request_body: &RequestBody) -> Option<RequestBody> {
        Some(RequestBody {
            content: request_body
                .content
                .iter()
                .filter_map(|(name, media_type)| Some((name.to_string(), media_type.visit(self)?)))
                .collect(),
            ..request_body.clone()
        })
    }

    fn visit_media_type(&mut self, media_type: &MediaType) -> Option<MediaType> {
        Some(MediaType {
            schema: media_type.schema.and_then(|schema| schema.visit(self)),
            ..media_type.clone()
        })
    }
}

pub fn visit_operation<'s>(
    visitor: &mut impl Visitor<'s>,
    (_path, _method, operation): OperationPath,
) -> Operation {
    Operation {
        parameters: operation
            .parameters
            .iter()
            .filter_map(|parameter| parameter.visit(visitor))
            .collect(),
        request_body: operation.request_body.and_then(|body| body.visit(visitor)),
        responses: Responses {
            default: operation
                .responses
                .default
                .and_then(|response| response.visit(visitor)),
            responses: operation
                .responses
                .responses
                .iter()
                .filter_map(|(status, response)| Some((status, response.visit(visitor)?)))
                .collect(),
            extensions: operation.responses.extensions,
        },
        ..operation.clone()
    }
}
