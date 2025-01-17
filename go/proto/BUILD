load("@rules_go//proto:def.bzl", "go_proto_library")

package(default_visibility = ["//go:__subpackages__"])

go_proto_library(
    name = "notification_queue_go_proto",
    compilers = [
        "@rules_go//proto:go_grpc_v2",
        "@rules_go//proto:go_proto",
    ],
    importpath = "github.com/EngFlow/engflowapis-go/engflow/notification/v1",
    protos = ["@engflowapis//engflow/notification/v1"],
    deps = [
        ":api_go_proto",
        "@org_golang_google_genproto_googleapis_rpc//status",
    ],
)

go_proto_library(
    name = "resourceusage_go_proto",
    importpath = "github.com/EngFlow/engflowapis-go/engflow/resourceusage/v1",
    protos = ["@engflowapis//engflow/resourceusage/v1"],
    deps = [":type_go_proto"],
)

go_proto_library(
    name = "api_go_proto",
    importpath = "github.com/EngFlow/engflowapis-go/engflow/api",
    protos = ["@engflowapis//engflow/api"],
    deps = [":type_go_proto"],
)

go_proto_library(
    name = "type_go_proto",
    importpath = "github.com/EngFlow/engflowapis-go/engflow/type",
    protos = ["@engflowapis//engflow/type"],
    deps = ["@org_golang_google_genproto_googleapis_api//annotations"],
)
