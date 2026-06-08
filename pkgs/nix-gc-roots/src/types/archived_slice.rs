use rkyv::util::AlignedVec;
use rkyv::{Portable, api::high::HighValidator, bytecheck::CheckBytes, rancor::Error};
use std::marker::PhantomData;
use std::ops::Deref;
use std::sync::Arc;

/// Owned rkyv-serialized data with zero-copy access.
///
/// Invariant: `bytes` always contains valid rkyv data for type `T`.
pub struct OwnedArchive<T: Portable> {
    bytes: Arc<AlignedVec>,
    _marker: PhantomData<T>,
}

impl<T: Portable> Clone for OwnedArchive<T> {
    fn clone(&self) -> Self {
        Self {
            bytes: Arc::clone(&self.bytes),
            _marker: PhantomData,
        }
    }
}

impl<T: Portable> OwnedArchive<T> {
    /// Create from bytes, validating they contain valid `T`.
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

    /// Create from bytes known to be valid (e.g. just serialized).
    pub fn from_bytes_unchecked(bytes: AlignedVec) -> Self {
        Self {
            bytes: Arc::new(bytes),
            _marker: PhantomData,
        }
    }

    pub fn as_slice(&self) -> &[u8] {
        &self.bytes
    }

    pub fn get(&self) -> &T {
        // Safety: struct invariant guarantees bytes are valid
        unsafe { rkyv::access_unchecked::<T>(&self.bytes) }
    }
}

impl<T: Portable> Deref for OwnedArchive<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        self.get()
    }
}
