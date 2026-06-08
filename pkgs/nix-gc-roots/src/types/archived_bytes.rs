use rkyv::Serialize;
use rkyv::api::high::HighSerializer;
use rkyv::ser::allocator::ArenaHandle;
use rkyv::util::AlignedVec;
use rkyv::{Portable, api::high::HighValidator, bytecheck::CheckBytes, rancor::Error};
use std::marker::PhantomData;
use std::ops::Deref;
use std::sync::Arc;

/// Owned rkyv-serialized data with zero-copy access.
///
/// Invariant: `bytes` always contains valid rkyv data for type `T`.
pub struct ArchivedBytes<T> {
    bytes: Arc<AlignedVec>,
    _marker: PhantomData<T>,
}

impl<T> Clone for ArchivedBytes<T> {
    fn clone(&self) -> Self {
        Self {
            bytes: Arc::clone(&self.bytes),
            _marker: PhantomData,
        }
    }
}

impl<T: Portable> ArchivedBytes<T> {
    pub fn from_value(value: &T) -> Result<Self, Error>
    where
        for<'t, 'a> &'t T: Serialize<HighSerializer<AlignedVec, ArenaHandle<'a>, Error>>,
    {
        let bytes = rkyv::to_bytes::<Error>(value)?;
        Ok(Self {
            bytes: Arc::new(bytes),
            _marker: PhantomData,
        })
    }

    pub fn from_bytes(bytes: AlignedVec) -> Result<Self, Error>
    where
        T: for<'a> CheckBytes<HighValidator<'a, Error>>,
    {
        let _ = rkyv::access::<T, Error>(&bytes)?;
        Ok(Self {
            bytes: Arc::new(bytes),
            _marker: PhantomData,
        })
    }

    pub fn as_slice(&self) -> &[u8] {
        &self.bytes
    }

    pub fn get(&self) -> &T {
        // Safety: struct invariant guarantees bytes are valid
        unsafe { rkyv::access_unchecked::<T>(&self.bytes) }
    }
}

impl<T: Portable> Deref for ArchivedBytes<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        self.get()
    }
}
