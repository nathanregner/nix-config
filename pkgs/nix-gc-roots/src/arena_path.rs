use std::collections::HashMap;
use std::fmt;
use std::hash::{Hash, Hasher};
use std::marker::PhantomData;
use std::ops::Deref;
use std::path::Path;

use context_deserialize::ContextDeserialize;
use serde::de::{DeserializeSeed, Deserializer, Error, MapAccess, SeqAccess, Visitor};
use stumpalo::Arena;

#[derive(Clone, Copy, Eq, PartialEq)]
pub struct ArenaPath<'a>(&'a str);

impl Hash for ArenaPath<'_> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.0.hash(state);
    }
}

impl<'a> ArenaPath<'a> {
    pub fn new(arena: &'a Arena, s: &str) -> Self {
        Self(arena.alloc_str(s))
    }
}

impl<'a> Deref for ArenaPath<'a> {
    type Target = Path;

    fn deref(&self) -> &Self::Target {
        Path::new(self.0)
    }
}

impl<'a> AsRef<Path> for ArenaPath<'a> {
    fn as_ref(&self) -> &Path {
        self
    }
}

impl fmt::Debug for ArenaPath<'_> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}", self.0)
    }
}

impl<'de, 'a> ContextDeserialize<'de, &'a Arena> for ArenaPath<'a> {
    fn context_deserialize<D>(deserializer: D, arena: &'a Arena) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct ArenaPathVisitor<'a>(&'a Arena);

        impl<'de, 'a> Visitor<'de> for ArenaPathVisitor<'a> {
            type Value = ArenaPath<'a>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a path string")
            }

            fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
            where
                E: Error,
            {
                Ok(ArenaPath::new(self.0, v))
            }
        }

        deserializer.deserialize_str(ArenaPathVisitor(arena))
    }
}

#[derive(Debug)]
pub struct PathInfo<'a> {
    pub nar_size: u64,
    pub references: Vec<ArenaPath<'a>>,
}

impl<'de, 'a> ContextDeserialize<'de, &'a Arena> for PathInfo<'a> {
    fn context_deserialize<D>(deserializer: D, arena: &'a Arena) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct PathInfoVisitor<'a>(&'a Arena);

        impl<'de, 'a> Visitor<'de> for PathInfoVisitor<'a> {
            type Value = PathInfo<'a>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a PathInfo object")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut nar_size: Option<u64> = None;
                let mut references: Option<Vec<ArenaPath<'a>>> = None;

                while let Some(key) = map.next_key::<&str>()? {
                    match key {
                        "narSize" => {
                            nar_size = Some(map.next_value()?);
                        }
                        "references" => {
                            references = Some(map.next_value_seed(VecSeed {
                                arena: self.0,
                                _marker: PhantomData,
                            })?);
                        }
                        _ => {
                            map.next_value::<serde::de::IgnoredAny>()?;
                        }
                    }
                }

                Ok(PathInfo {
                    nar_size: nar_size.ok_or_else(|| A::Error::missing_field("narSize"))?,
                    references: references
                        .ok_or_else(|| A::Error::missing_field("references"))?,
                })
            }
        }

        deserializer.deserialize_map(PathInfoVisitor(arena))
    }
}

#[derive(Debug)]
pub struct PathInfoMap<'a>(HashMap<ArenaPath<'a>, PathInfo<'a>>);

impl<'a> PathInfoMap<'a> {
    pub fn len(&self) -> usize {
        self.0.len()
    }

    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }

    pub fn get(&self, key: &ArenaPath<'a>) -> Option<&PathInfo<'a>> {
        self.0.get(key)
    }

    pub fn iter(&self) -> impl Iterator<Item = (&ArenaPath<'a>, &PathInfo<'a>)> {
        self.0.iter()
    }
}

impl<'de, 'a> ContextDeserialize<'de, &'a Arena> for PathInfoMap<'a> {
    fn context_deserialize<D>(deserializer: D, arena: &'a Arena) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct PathInfoMapVisitor<'a>(&'a Arena);

        impl<'de, 'a> Visitor<'de> for PathInfoMapVisitor<'a> {
            type Value = PathInfoMap<'a>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a map of paths to PathInfo")
            }

            fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
            where
                A: MapAccess<'de>,
            {
                let mut result = HashMap::with_capacity(map.size_hint().unwrap_or(0));

                while let Some(key) = map.next_key_seed(ContextSeed {
                    arena: self.0,
                    _marker: PhantomData::<ArenaPath>,
                })? {
                    let value = map.next_value_seed(ContextSeed {
                        arena: self.0,
                        _marker: PhantomData::<PathInfo>,
                    })?;
                    result.insert(key, value);
                }

                Ok(PathInfoMap(result))
            }
        }

        deserializer.deserialize_map(PathInfoMapVisitor(arena))
    }
}

struct ContextSeed<'a, T> {
    arena: &'a Arena,
    _marker: PhantomData<T>,
}

impl<'de, 'a, T> DeserializeSeed<'de> for ContextSeed<'a, T>
where
    T: ContextDeserialize<'de, &'a Arena>,
{
    type Value = T;

    fn deserialize<D>(self, deserializer: D) -> Result<T, D::Error>
    where
        D: Deserializer<'de>,
    {
        T::context_deserialize(deserializer, self.arena)
    }
}

struct VecSeed<'a, T> {
    arena: &'a Arena,
    _marker: PhantomData<T>,
}

impl<'de, 'a, T> DeserializeSeed<'de> for VecSeed<'a, T>
where
    T: ContextDeserialize<'de, &'a Arena>,
{
    type Value = Vec<T>;

    fn deserialize<D>(self, deserializer: D) -> Result<Vec<T>, D::Error>
    where
        D: Deserializer<'de>,
    {
        struct VecVisitor<'a, T> {
            arena: &'a Arena,
            _marker: PhantomData<T>,
        }

        impl<'de, 'a, T> Visitor<'de> for VecVisitor<'a, T>
        where
            T: ContextDeserialize<'de, &'a Arena>,
        {
            type Value = Vec<T>;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a sequence")
            }

            fn visit_seq<A>(self, mut seq: A) -> Result<Vec<T>, A::Error>
            where
                A: SeqAccess<'de>,
            {
                let mut result = Vec::with_capacity(seq.size_hint().unwrap_or(0));
                while let Some(elem) = seq.next_element_seed(ContextSeed {
                    arena: self.arena,
                    _marker: PhantomData,
                })? {
                    result.push(elem);
                }
                Ok(result)
            }
        }

        deserializer.deserialize_seq(VecVisitor {
            arena: self.arena,
            _marker: PhantomData,
        })
    }
}
