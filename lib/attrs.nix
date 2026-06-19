{lib}: {
  # Recursively merge a list of attribute sets
  recursiveMerge = attrsList:
    lib.foldl' (acc: attrs: lib.recursiveUpdate acc attrs) {} attrsList;

  # Filter out null values from an attribute set
  filterNullAttrs = attrs:
    lib.filterAttrs (_: v: v != null) attrs;

  # Proudly found here: https://github.com/yunfachi/nypkgs/blob/master/lib/umport.nix
  umport = {
    path ? null,
    paths ? [],
    include ? [],
    exclude ? [],
    recursive ? true,
  }:
    with lib;
    with fileset; let
      excludedFiles = filter pathIsRegularFile exclude;
      excludedDirs = filter pathIsDirectory exclude;
      isExcluded = path:
        if elem path excludedFiles
        then true
        else (filter (excludedDir: lib.path.hasPrefix excludedDir path) excludedDirs) != [];
    in
      unique (
        (
          filter
          (file: pathIsRegularFile file && hasSuffix ".nix" (builtins.toString file) && !isExcluded file)
          (
            concatMap (
              _path:
                if recursive
                then toList _path
                else
                  mapAttrsToList (
                    name: type:
                      _path
                      + (
                        if type == "directory"
                        then "/${name}/default.nix"
                        else "/${name}"
                      )
                  ) (
                    if excludeDotPaths
                    then removeDotPaths (builtins.readDir _path)
                    else builtins.readDir _path
                  )
            ) (unique (
              if path == null
              then paths
              else [path] ++ paths
            ))
          )
        )
        ++ (
          if recursive
          then concatMap toList (unique include)
          else unique include
        )
      );
}
