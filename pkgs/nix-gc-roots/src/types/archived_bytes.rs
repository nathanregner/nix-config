use std::{hash::Hash, marker::PhantomData, ops::Deref, sync::Arc};

use rkyv::{
    Archive, Archived, Portable, Serialize,
    api::high::{HighSerializer, HighValidator},
    bytecheck::CheckBytes,
    rancor::Error,
    ser::allocator::ArenaHandle,
    util::AlignedVec,
};

/// Owned rkyv-serialized data with zero-copy access.
///
/// Invariant: `bytes` is a valid representation of `T::Archived`
pub struct ArchivedBytes<'a, T: Archive> {
    repr: Repr<'a>,
    _ty: PhantomData<T>,
}

impl<'a, T: Archive> Clone for ArchivedBytes<'a, T> {
    fn clone(&self) -> Self {
        Self {
            repr: self.repr.clone(),
            _ty: PhantomData,
        }
    }
}

#[derive(Clone)]
enum Repr<'a> {
    Owned(Arc<AlignedVec>),
    Borrowed(&'a [u8]),
}

impl<'a> Repr<'a> {
    pub fn as_slice(&self) -> &[u8] {
        match &self {
            Repr::Owned(vec) => vec.as_slice(),
            Repr::Borrowed(slice) => slice,
        }
    }
}

impl<'a, T: Archive> ArchivedBytes<'a, T> {
    pub fn from_value(value: &T) -> Result<Self, Error>
    where
        T: for<'h> Serialize<HighSerializer<AlignedVec, ArenaHandle<'h>, Error>>,
    {
        // Invariant: `bytes` is a valid representation of `T::Archived`
        let vec = rkyv::to_bytes(value)?;
        Ok(Self {
            repr: Repr::Owned(Arc::new(vec)),
            _ty: PhantomData,
        })
    }

    pub fn from_bytes(bytes: &'a [u8]) -> Result<Self, Error>
    where
        T::Archived: for<'b> CheckBytes<HighValidator<'b, Error>>,
    {
        // use std::sync::atomic::{AtomicUsize, Ordering};
        // static ALIGNED: AtomicUsize = AtomicUsize::new(0);
        // static UNALIGNED: AtomicUsize = AtomicUsize::new(0);

        // HACK: most of the time it's aligned (something like 85%), but not always
        // https://github.com/meilisearch/heed/issues/198#issuecomment-2799936076
        let repr = if !(bytes.as_ptr() as usize).is_multiple_of(16) {
            // let prev = UNALIGNED.fetch_add(1, Ordering::Relaxed);
            // if prev % 100 == 0 {
            //     eprintln!(
            //         "ALIGNMENT: {} aligned, {} unaligned (copying)",
            //         ALIGNED.load(Ordering::Relaxed),
            //         prev + 1
            //     );
            // }
            let mut vec = AlignedVec::<16>::with_capacity(bytes.len());
            vec.extend_from_slice(bytes);
            Repr::Owned(Arc::new(vec))
        } else {
            // ALIGNED.fetch_add(1, Ordering::Relaxed);
            Repr::Borrowed(bytes)
        };
        // Invariant: `bytes` is a valid representation of `T::Archived`
        let _ = rkyv::access::<Archived<T>, Error>(repr.as_slice())?;
        Ok(Self {
            repr,
            _ty: PhantomData,
        })
    }

    pub fn as_slice(&self) -> &[u8] {
        self.repr.as_slice()
    }
}

impl<T: Archive> Deref for ArchivedBytes<'_, T>
where
    T::Archived: Portable,
{
    type Target = T::Archived;

    fn deref(&self) -> &Self::Target {
        // Safety: struct invariant guarantees `bytes` are valid for `T::Archived`
        unsafe { rkyv::access_unchecked::<Archived<T>>(self.as_slice()) }
    }
}

impl<T: Archive> Hash for ArchivedBytes<'_, T>
where
    T::Archived: Hash,
{
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.deref().hash(state);
    }
}

impl<T: Archive> PartialEq for ArchivedBytes<'_, T>
where
    T::Archived: PartialEq,
{
    fn eq(&self, other: &Self) -> bool {
        self.deref() == other.deref()
    }
}

impl<T: Archive> Eq for ArchivedBytes<'_, T> where T::Archived: Eq {}
