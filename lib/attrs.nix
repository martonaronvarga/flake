{lib}: {
  # Recursively merge a list of attribute sets
  recursiveMerge = attrsList:
    lib.foldl' (acc: attrs: lib.recursiveUpdate acc attrs) {} attrsList;

  # Filter out null values from an attribute set
  filterNullAttrs = attrs:
    lib.filterAttrs (_: v: v != null) attrs;
}
