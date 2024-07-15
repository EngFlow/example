package(default_visibility = ["//visibility:public"])

platform(
    name = "platform",
    exec_properties = {
        # Explicitly does not include a container-image as that is set by the genrule target to use DinD
        "OSFamily": "Linux",
    },
)