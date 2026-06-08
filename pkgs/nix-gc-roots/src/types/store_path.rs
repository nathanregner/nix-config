use std::borrow::Borrow;
use std::ffi::OsStr;
use std::ops::Deref;
use std::os::unix::ffi::OsStrExt;
use std::path::Path;
use std::path::PathBuf;

use rkyv::Place;
use rkyv::rancor::Fallible;
use rkyv::ser::Allocator;
use rkyv::ser::Writer;
use rkyv::vec::ArchivedVec;
use rkyv::vec::VecResolver;
use rkyv::with::{ArchiveWith, DeserializeWith, SerializeWith};

#[derive(Hash, Eq, PartialEq, Clone, Debug)] //
#[derive(serde::Serialize, serde::Deserialize)] //
#[derive(rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)] //
#[rkyv(derive(Hash, PartialEq, Eq))]
#[serde(transparent)]
pub struct StorePath(#[rkyv(with = PathBufAsBytes)] pub PathBuf);

impl<T> From<T> for StorePath
where
    PathBuf: From<T>,
{
    fn from(path: T) -> Self {
        Self(path.into())
    }
}

impl Deref for StorePath {
    type Target = PathBuf;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl Borrow<PathBuf> for StorePath {
    fn borrow(&self) -> &PathBuf {
        &self.0
    }
}

impl ArchivedStorePath {
    pub fn as_path(&self) -> &Path {
        Path::new(OsStr::from_bytes(&self.0))
    }

    pub fn to_path_buf(&self) -> PathBuf {
        self.as_path().to_path_buf()
    }
}

struct PathBufAsBytes;

impl ArchiveWith<PathBuf> for PathBufAsBytes {
    type Archived = ArchivedVec<u8>;
    type Resolver = VecResolver;

    fn resolve_with(field: &PathBuf, resolver: Self::Resolver, out: Place<Self::Archived>) {
        ArchivedVec::resolve_from_slice(field.as_os_str().as_bytes(), resolver, out);
    }
}

impl<S: Allocator + Writer + Fallible + ?Sized> SerializeWith<PathBuf, S> for PathBufAsBytes {
    fn serialize_with(
        field: &PathBuf,
        serializer: &mut S,
    ) -> Result<Self::Resolver, <S as Fallible>::Error> {
        ArchivedVec::serialize_from_slice(field.as_os_str().as_bytes(), serializer)
    }
}

impl<D: Fallible + ?Sized> DeserializeWith<ArchivedVec<u8>, PathBuf, D> for PathBufAsBytes {
    fn deserialize_with(
        field: &ArchivedVec<u8>,
        _deserializer: &mut D,
    ) -> Result<PathBuf, <D as Fallible>::Error> {
        Ok(PathBuf::from(OsStr::from_bytes(field)))
    }
}
