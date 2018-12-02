def _expand_libs(imps):
  res = []
  for i in imps:
    res.append("//{}:{}.lib".format(i, i))
  
  return res

def _expand_sos(imps):
  res = []
  for i in imps:
    res.append("//{}:{}_so".format(i, i))
  
  return res

def _expand_dylibs(imps):
  res = []
  for i in imps:
    res.append("//{}:{}_dylib".format(i, i))
  
  return res


def header_generator(packages=[], extra_headers=[], deps=[]):
  pname = native.package_name().split("/")[-1]
  native.cc_library(
    name = "headers",
    hdrs = native.glob([
    "src/" + pname + "/**/*.h*",
    ]) + extra_headers,
    includes = ["src"],
    visibility = ["//visibility:public"],
    deps = packages + deps
  )

def dll_generator(packages=[], deps=[], linkopts=[]):
  pname = native.package_name().split("/")[-1]
  native.genrule(
    name = pname + "_importlib",
    outs = [pname + ".lib"],
    srcs = [pname + ".dll"],
    cmd = select({
        "@bazel_tools//src/conditions:windows": "cp ./$(location " + pname + ".dll).if.lib \"$@\"",
        "//conditions:default": "touch ./$(location " + pname + ".dll).if.lib \"$@\"",
    }),
    visibility = ["//visibility:public"],
  )

  native.cc_binary(
    name = "lib" + pname + ".so",
    visibility = ["//visibility:public"],
    linkshared = 1,
    linkopts = linkopts + ["-lpthread", "-ldl", "-lstdc++fs"],
    srcs = native.glob(["src/" + pname + "/**/*.c*", "src/" + pname + "/**/*.h*"]),
    deps = ["headers"] + deps,
    copts = ["-std=c++17"],
    defines = [
      "CULTLANG_"+ pname.upper() + "_DLL", 
      "CULT_CURRENT_PACKAGE=\\\"org_cultlang_" + pname + "\\\""
    ] + select({
      "//build_tools:cult_trace": ["CULT_TRACE"],
      "//build_tools:cult_debug": ["CULT_DEBUG"],
      "//conditions:default": [],
    }),
  )

  native.cc_binary(
    name = pname + ".dylib",
    visibility = ["//visibility:public"],
    linkshared = 1,
    linkopts = linkopts,
    srcs = native.glob(["src/" + pname + "/**/*.c*", "src/" + pname + "/**/*.h*"]),
    deps = ["headers"] + deps,
    copts = ["-std=c++17"],
    defines = [
      "CULTLANG_"+ pname.upper() + "_DLL", 
      "CULT_CURRENT_PACKAGE=\\\"org_cultlang_" + pname + "\\\""
    ] + select({
      "//build_tools:cult_trace": ["CULT_TRACE"],
      "//build_tools:cult_debug": ["CULT_DEBUG"],
      "//conditions:default": [],
    }),
  )
  
  native.cc_binary(
    name = pname + ".dll",
    visibility = ["//visibility:public"],
    linkshared = 1,
    linkopts = ["/ENTRY:_craft_types_DLLMAIN"] + linkopts,
    srcs = native.glob(["src/" + pname + "/**/*.c*", "src/" + pname + "/**/*.h*"]) + _expand_libs(packages),
    deps = ["headers"] + deps,
    copts = ["/std:c++17"],
    defines = [
      "CULTLANG_"+ pname.upper() + "_DLL", 
      "CULT_CURRENT_PACKAGE=\\\"org_cultlang_" + pname + "\\\""
    ] + select({
      "//build_tools:cult_trace": ["CULT_TRACE"],
      "//build_tools:cult_debug": ["CULT_DEBUG"],
      "//conditions:default": [],
    }),
  )

  native.cc_import(
    name = pname + "_so",
    visibility = ["//visibility:public"],
    shared_library = "lib" + pname + ".so",
  )

  native.cc_import(
    name = pname + "_dylib",
    visibility = ["//visibility:public"],
    shared_library = pname + ".dylib",
  )

  native.cc_import(
    name = pname + "_lib",
    interface_library = pname + ".lib",
    visibility = ["//visibility:public"],
    shared_library = pname + ".dll",
  )

  native.cc_library(
      name = pname,
      includes = ["src"],
      deps = select({
        "@bazel_tools//src/conditions:windows": ["headers", pname + "_lib"],
        "@bazel_tools//src/conditions:darwin": ["headers", pname + "_dylib"],
        "//conditions:default": ["headers", pname + "_so"],
      }),
      visibility = ["//visibility:public"], 
  )


def entrypoint_generator(name, packages=[],  deps=[]):

  pname = native.package_name().split("/")[-1]

  local_dlls = []
  for i in packages:
    native.genrule(
      name = "local_" + i + "_dll",
      outs = [i + ".dll"],
      srcs = ["//{}:{}.dll".format(i, i)],
      cmd = "cp \"$<\" \"$@\"",
      visibility = ["//visibility:public"],
      output_to_bindir = 1
    )

    local_dlls.append("{}.dll".format(i))

  native.cc_binary(
    name = name,
    srcs = select({
        "@bazel_tools//src/conditions:windows": native.glob(["entry/**/*"]) + _expand_libs(packages),
        "@bazel_tools//src/conditions:darwin": native.glob(["entry/**/*"]),
        "//conditions:default": native.glob(["entry/**/*"])
    }),
    data = select({
        "@bazel_tools//src/conditions:windows": local_dlls,
        "@bazel_tools//src/conditions:darwin": [],
        "//conditions:default": [],
    }),
    linkopts= select ({
      "@bazel_tools//src/conditions:windows": [],
      "@bazel_tools//src/conditions:darwin": [],
      "//conditions:default": ["-lpthread", "-ldl", "-lstdc++fs"],
    }),
    deps = select({
        "@bazel_tools//src/conditions:windows": [pname] + [ "headers"] + deps,
        "@bazel_tools//src/conditions:darwin": [pname] +  [ "headers"] + deps + _expand_dylibs(packages),
        "//conditions:default": [pname] + [ "headers"] + deps + _expand_sos(packages),
    }),
    
    copts = select({
        "@bazel_tools//src/conditions:windows": ["/std:c++latest"],
        "@bazel_tools//src/conditions:darwin": ["-std=c++17"],
        "//conditions:default": ["-std=c++17"],
    }),
  )
