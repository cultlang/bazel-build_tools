def header_generator(extra_headers=[], deps=[]):
  native.cc_library(
    name = native.package_name() + "_hdrs",
    hdrs = native.glob([
    "src/" + native.package_name() + "/**/*.h*",
    ]) + extra_headers,
    includes = ["src"],
    visibility = ["//visibility:public"],
    deps = deps
  )

def dll_generator(deps=[]):
  native.genrule(
    name = "org_cultlang_" + native.package_name() + "_importlib",
    outs = ["org_cultlang_" + native.package_name() + ".lib"],
    srcs = ["org_cultlang_" + native.package_name() + ".dll"],
    cmd = "cp ./$(location " + "org_cultlang_" + native.package_name() + ".dll).if.lib \"$@\"",
    visibility = ["//visibility:public"],
  )

  native.cc_binary(
    name = "org_cultlang_"+ native.package_name() + ".dll",
    linkshared = 1,
    srcs = native.glob([
      "src/" + native.package_name() + "/**/*.c*",
      "src/" + native.package_name() + "/**/*.c*",
    ]),
    
    deps = [native.package_name() + "_hdrs"] + deps,
    
    copts = ["/std:c++latest"],
    defines = ["CULTLANG_"+ native.package_name().upper() + "_DLL", 
      "CULT_CURRENT_PACKAGE=\\\"org_cultlang_" + native.package_name() + "\\\""
    ],
  )

  native.cc_import(
    name = native.package_name() + "_lib",
    interface_library = "org_cultlang_" + native.package_name() + ".lib",
    visibility = ["//visibility:public"],
    shared_library = "org_cultlang_" + native.package_name() + ".dll",
  )

  native.cc_library(
    visibility = ["//visibility:public"],
    name = "org_cultlang_" + native.package_name() + "_import",
    srcs = ["org_cultlang_" + native.package_name() + ".lib"],
  )

  native.cc_library(
      name = native.package_name(),
      includes = ["src"],
      deps = [native.package_name() + "_hdrs", native.package_name() + "_lib"],
      visibility = ["//visibility:public"], 
  )

def entrypoint_generator(name, deps=[]):
  native.cc_binary(
    name = name,
    srcs = native.glob(["entry/**/*"]),
    
    deps = ["//" + native.package_name()] + deps,
    
    copts = ["/std:c++latest"]
  )
