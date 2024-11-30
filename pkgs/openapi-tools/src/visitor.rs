use indexmap::IndexMap;
use openapiv3::{
    AdditionalProperties, ArrayType, MediaType, ObjectType, Operation, Parameter, ParameterData,
    ParameterSchemaOrContent, PathItem, ReferenceOr, RequestBody, Response, Responses, Schema,
    SchemaKind, Type,
};
use strum::VariantArray;

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
        Some(Box::new(Schema::visit(self, visitor)?))
    }
}

impl<'s> Visit<'s> for ObjectType {
    type Output = Option<Type>;

    fn visit(&self, visitor: &mut impl Visitor<'s>) -> <Self as Visit<'s>>::Output {
        visitor.visit_object_type(&self)
    }
}

impl<'s> Visit<'s> for ArrayType {
    type Output = Option<Type>;

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

        for &method in Method::VARIANTS {
            if let Some(operation) = method.get(&path_item) {
                let operation = (path, method, operation).visit(self);
                *method.get_mut(&mut result) = operation;
            }
        }

        Some(result)
    }

    fn visit_schema(&mut self, schema: &Schema) -> Option<Schema> {
        visit_schema(self, schema)
    }

    fn visit_ref<T>(&mut self, reference: &str) -> Option<ReferenceOr<T>>;

    fn visit_object_type(&mut self, schema: &ObjectType) -> Option<Type> {
        use AdditionalProperties::*;
        Some(Type::Object(ObjectType {
            properties: schema
                .properties
                .iter()
                .filter_map(|(name, property)| Some((name.to_string(), property.visit(self)?)))
                .collect(),
            additional_properties: schema.additional_properties.as_ref().and_then(
                |additional_properties| {
                    Some(match additional_properties {
                        Schema(additional_properties) => {
                            Schema(Box::new(additional_properties.visit(self)?))
                        }
                        _ => additional_properties.clone(),
                    })
                },
            ),
            ..schema.clone()
        }))
    }

    fn visit_array_type(&mut self, schema: &ArrayType) -> Option<Type> {
        let schema = visit_array(self, schema);
        Some(Type::Array(schema))
    }

    fn visit_operation<'o: 's>(&mut self, operation: OperationPath<'o>) -> Option<Operation> {
        Some(visit_operation(self, operation))
    }

    fn visit_parameter(&mut self, parameter: &Parameter) -> Option<Parameter> {
        use Parameter::*;
        use ParameterSchemaOrContent::*;

        let mut parameter = parameter.clone();
        match &mut parameter {
            Query { parameter_data, .. }
            | Header { parameter_data, .. }
            | Path { parameter_data, .. }
            | Cookie { parameter_data, .. } => {
                let format = match &parameter_data.format {
                    Schema(schema) => Schema(schema.visit(self)?),
                    Content(content) => Content(
                        content
                            .iter()
                            .filter_map(|(name, media_type)| {
                                Some((name.to_string(), media_type.visit(self)?))
                            })
                            .collect(),
                    ),
                };
                parameter_data.format = format;
            }
        }
        Some(parameter)
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
            schema: media_type
                .schema
                .as_ref()
                .and_then(|schema| schema.visit(self)),
            ..media_type.clone()
        })
    }
}

fn visit_array<'s>(visitor: &mut impl Visitor<'s>, schema: &ArrayType) -> ArrayType {
    let mut schema = schema.clone();
    if let Some(items) = &schema.items {
        schema.items = items.visit(visitor);
    }
    schema
}

pub fn visit_parameter_data<'s>(
    visitor: &mut impl Visitor<'s>,
    parameter_data: &ParameterData,
) -> Option<ParameterData> {
    use ParameterSchemaOrContent::*;
    let format = match &parameter_data.format {
        Schema(schema) => Schema(schema.visit(visitor)?),
        Content(content) => Content(visit_content(visitor, content)),
    };
    Some(ParameterData {
        format,
        ..parameter_data.clone()
    })
}

pub fn visit_content<'s>(
    visitor: &mut impl Visitor<'s>,
    content: &IndexMap<String, MediaType>,
) -> IndexMap<String, MediaType> {
    content
        .iter()
        .filter_map(|(name, media_type)| Some((name.to_string(), media_type.visit(visitor)?)))
        .collect()
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
        request_body: operation
            .request_body
            .as_ref()
            .and_then(|body| body.visit(visitor)),
        responses: Responses {
            default: operation
                .responses
                .default
                .as_ref()
                .and_then(|response| response.visit(visitor)),
            responses: operation
                .responses
                .responses
                .iter()
                .filter_map(|(status, response)| {
                    Some((status.to_owned(), response.visit(visitor)?))
                })
                .collect(),
            extensions: operation.responses.extensions.clone(),
        },
        ..operation.clone()
    }
}

pub fn visit_schema<'s>(visitor: &mut impl Visitor<'s>, schema: &Schema) -> Option<Schema> {
    use openapiv3::{SchemaKind::*, Type::*};

    let schema_kind = match &schema.schema_kind {
        Type(t) => Type(match t {
            Object(object) => visitor.visit_object_type(object)?,
            Array(array) => visitor.visit_array_type(array)?,
            t @ String(_) | t @ Number(_) | t @ Integer(_) | t @ Boolean(_) => t.clone(),
        }),
        OneOf { one_of } => OneOf {
            one_of: one_of.iter().filter_map(|s| s.visit(visitor)).collect(),
        },
        AllOf { all_of } => AllOf {
            all_of: all_of.iter().filter_map(|s| s.visit(visitor)).collect(),
        },
        AnyOf { any_of } => AnyOf {
            any_of: any_of.iter().filter_map(|s| s.visit(visitor)).collect(),
        },
        Not { not } => Not {
            not: Box::new(not.visit(visitor)?),
        },
        any @ Any(_) => any.clone(),
    };
    Some(Schema {
        schema_kind,
        ..schema.clone()
    })
}
