def _expand_importlibs(imps):
  res = []
  for i in imps:
    res.append("$(location //" + i + ":" + i + ".dll).if.lib")
  return res

def make_impdep(imps):
  res = []
  for i in imps:
    res.append("//{}:{}.dll".format(i, i))
  return res

def header_generator(packages=[], extra_headers=[], deps=[]):
  native.cc_library(
    name = "headers",
    hdrs = native.glob([
    "src/" + native.package_name() + "/**/*.h*",
    ]) + extra_headers,
    includes = ["src"],
    visibility = ["//visibility:public"],
    deps = packages + deps
  )

def dll_generator(packages=[], deps=[]):
  native.genrule(
    name = native.package_name() + "_importlib",
    outs = [native.package_name() + ".lib"],
    srcs = [native.package_name() + ".dll"],
    cmd = "cp ./$(location " + native.package_name() + ".dll).if.lib \"$@\"",
    visibility = ["//visibility:public"],
  )

  native.cc_binary(
    name = native.package_name() + ".dll",
    visibility = ["//visibility:public"],
    linkshared = 1,
    linkopts = _expand_importlibs(packages) + [
      "/ENTRY:_craft_types_DLLMAIN"
    ],
    srcs = native.glob([
      "src/" + native.package_name() + "/**/*.c*",
      "src/" + native.package_name() + "/**/*.c*",
    ]),
    data = make_impdep(packages),
    deps = ["headers"] + deps,
    
    copts = ["/std:c++latest"],
    defines = ["CULTLANG_"+ native.package_name().upper() + "_DLL", 
      "CULT_CURRENT_PACKAGE=\\\"org_cultlang_" + native.package_name() + "\\\""
    ],
  )

  native.cc_import(
    name = native.package_name() + "_lib",
    interface_library = native.package_name() + ".lib",
    visibility = ["//visibility:public"],
    shared_library = native.package_name() + ".dll",
  )

  native.cc_library(
    visibility = ["//visibility:public"],
    name = native.package_name() + "_import",
    srcs = [native.package_name() + ".lib"],
  )

  native.cc_library(
      name = native.package_name(),
      includes = ["src"],
      deps = ["headers", native.package_name() + "_lib"],
      visibility = ["//visibility:public"], 
  )

def entrypoint_generator(name, packages=[],  deps=[]):
  native.cc_binary(
    name = name,
    srcs = native.glob(["entry/**/*"]),
    linkopts = _expand_importlibs(packages),
    data = make_impdep(packages),
    deps = [native.package_name()] + deps,
    
    copts = ["/std:c++latest"]
  )
