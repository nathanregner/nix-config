use std::ops::Deref;
use std::{borrow::Borrow, hash::Hash};

use rkyv::{Archive, Deserialize, Serialize};

/// Guarantees 16-byte alignment for zero-copy reads from LMDB
#[derive(Archive, Serialize, Deserialize)]
#[rkyv(attr(repr(C, align(16))))]
pub struct Aligned<T>(pub T);

impl<T> Deref for Aligned<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<T> Borrow<T> for Aligned<T> {
    fn borrow(&self) -> &T {
        &self.0
    }
}

impl<T: Hash> Hash for Aligned<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.0.hash(state);
    }
}

impl<T: PartialEq> PartialEq for Aligned<T> {
    fn eq(&self, other: &Self) -> bool {
        self.0 == other.0
    }
}

impl<T: Eq> Eq for Aligned<T> {}

impl<T: Archive> Hash for ArchivedAligned<T>
where
    T::Archived: Hash,
{
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.0.hash(state);
    }
}

impl<T: Archive> PartialEq for ArchivedAligned<T>
where
    T::Archived: PartialEq,
{
    fn eq(&self, other: &Self) -> bool {
        self.0 == other.0
    }
}

impl<T: Archive> Eq for ArchivedAligned<T> where T::Archived: Eq {}

#[cfg(test)]
mod tests {
    use std::{any::type_name_of_val, ops::Range};

    use rkyv::rancor::Error;

    use super::*;

    macro_rules! assert_aligned {
        ($value:expr) => {{
            let bytes = rkyv::to_bytes::<Error>(&Aligned($value)).unwrap();
            let Range { start, end } = bytes.as_ptr_range();
            let ty = type_name_of_val(&$value);
            assert_eq!(
                (start as usize % 16, end as usize % 16),
                (0, 0),
                "Expected 16-byte alignment of {ty}($value:?)"
            );
        }};
    }

    #[test]
    fn aligned() {
        assert_aligned!(0u8);
        assert_aligned!(vec![1, 2, 3]);
    }
}
