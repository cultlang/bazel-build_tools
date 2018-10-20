def _expand_importlibs(imps):
  res = []
  for i in imps:
    res.append("$(location //" + i + ":" + i + ".dll).if.lib")
  return res

def _expand_libs(imps):
  res = []
  for i in imps:
    res.append("//{}:{}.lib".format(i, i))
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
    cmd = "cp ./$(location " + pname + ".dll).if.lib \"$@\"",
    visibility = ["//visibility:public"],
  )
  
  native.cc_binary(
    name = pname + ".dll",
    visibility = ["//visibility:public"],
    linkshared = 1,
    linkopts = [
      "/ENTRY:_craft_types_DLLMAIN"
    ] + linkopts,
    srcs = native.glob([
      "src/" + pname + "/**/*.c*",
      "src/" + pname + "/**/*.h*",
    ]) + _expand_libs(packages),
    deps = ["headers"] + deps,
    
    copts = ["/std:c++latest"],
    defines = ["CULTLANG_"+ pname.upper() + "_DLL", 
      "CULT_CURRENT_PACKAGE=\\\"org_cultlang_" + pname + "\\\""
    ],
  )

  native.cc_import(
    name = pname + "_lib",
    interface_library = pname + ".lib",
    data = [pname + ".lib"],
    visibility = ["//visibility:public"],
    shared_library = pname + ".dll",
  )

  native.cc_library(
      name = pname,
      includes = ["src"],
      deps = ["headers", pname + "_lib"],
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
    srcs = native.glob(["entry/**/*"]) + _expand_libs(packages),
    data = local_dlls,
    deps = [pname] + deps,
    
    copts = ["/std:c++latest"]
  )
