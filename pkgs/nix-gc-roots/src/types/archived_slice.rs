use rkyv::{Portable, api::high::HighValidator, bytecheck::CheckBytes, rancor::Error};
use std::ops::Deref;

pub struct ArchivedSlice<'a, T> {
    bytes: &'a [u8],
    archived: &'a T,
}

impl<'a, T> Clone for ArchivedSlice<'a, T> {
    fn clone(&self) -> Self {
        Self {
            bytes: self.bytes,
            archived: self.archived,
        }
    }
}

impl<'a, T> ArchivedSlice<'a, T>
where
    T: Portable + for<'b> CheckBytes<HighValidator<'b, Error>>,
{
    pub fn new(bytes: &'a [u8]) -> Result<Self, Error> {
        let archived = rkyv::access::<T, Error>(bytes)?;
        Ok(Self { bytes, archived })
    }

    pub fn as_slice(&self) -> &'a [u8] {
        self.bytes
    }
}

impl<T> Deref for ArchivedSlice<'_, T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        self.archived
    }
}
