use rkyv::Archive;
use rkyv::api::high::HighSerializer;
use rkyv::ser::allocator::ArenaHandle;
use rkyv::util::AlignedVec;
use rkyv::{Portable, api::high::HighValidator, bytecheck::CheckBytes, rancor::Error};
use std::marker::PhantomData;
use std::ops::Deref;

/// Owned rkyv-serialized data with zero-copy access.
///
/// Invariant: `bytes` is a valid representation of `T::Archived`.
pub struct ArchivedBytes<T: Archive> {
    bytes: AlignedVec,
    _ty: PhantomData<T>,
}

impl<T: Archive> ArchivedBytes<T> {
    pub fn from_value(value: &T) -> Result<Self, Error>
    where
        T: for<'a> rkyv::Serialize<HighSerializer<AlignedVec, ArenaHandle<'a>, Error>>,
    {
        // Safety: `bytes` is a valid representation of `T::Archived`
        let bytes = rkyv::to_bytes::<Error>(value)?;
        Ok(Self {
            bytes,
            _ty: PhantomData,
        })
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, Error>
    where
        T::Archived: for<'a> CheckBytes<HighValidator<'a, Error>>,
    {
        let mut aligned = AlignedVec::with_capacity(bytes.len());
        aligned.extend_from_slice(bytes);
        let bytes = aligned;

        // Safety: verify `bytes` is a valid representation of `T::Archived`
        let _ = rkyv::access::<T::Archived, Error>(bytes.as_slice())?;
        Ok(Self {
            bytes,
            _ty: PhantomData,
        })
    }

    pub fn as_slice(&self) -> &[u8] {
        &self.bytes
    }
}

impl<T: Archive> Deref for ArchivedBytes<T>
where
    T::Archived: Portable,
{
    type Target = T::Archived;

    fn deref(&self) -> &Self::Target {
        // Safety: struct invariant guarantees `bytes` are valid for `T::Archived`
        unsafe { rkyv::access_unchecked::<T::Archived>(&self.bytes) }
    }
}
