using ObjectPools
using Documenter

DocMeta.setdocmeta!(ObjectPools, :DocTestSetup, :(using ObjectPools); recursive=true)

makedocs(;
    modules=[ObjectPools],
    authors="Christoph Ortner <christohortner@gmail.com> and contributors",
    repo="https://github.com/ACEsuit/ObjectPools.jl/blob/{commit}{path}#{line}",
    sitename="ObjectPools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ACEsuit.github.io/ObjectPools.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ACEsuit/ObjectPools.jl",
    devbranch="main",
)
