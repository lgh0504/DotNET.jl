module CLR

export CLRObject,null,CLRException,@Type_str
export clrtypeof,isclrtype

include("typedef.jl")

include("CoreCLR.jl")
using .CoreCLR

include("CLRBridge.jl")
using .CLRBridge

include("marshalling.jl")

include("invocation.jl")

struct DummyCLRHost <: CLRHost end

const CURRENT_CLR_HOST = Ref{CLRHost}(DummyCLRHost())

function __init__()
    if CURRENT_CLR_HOST[] != DummyCLRHost() return end
    coreclr = detect_runtime(CoreCLRHost)
    if !isempty(coreclr)
        init_coreclr(first(coreclr))
        return
    end
    @error "No .NET Core runtime found on this system."
end

function init_coreclr(runtime)
    CoreCLR.init(runtime)
    clrbridge = raw"C:\Users\Azure\Documents\Git\CLRBridge\CLRBridge\bin\Debug\netstandard2.0\CLRBridge.dll"
    if !isfile(clrbridge)
        error("CLRBridge.dll not found")
    end
    tpalist = build_tpalist(dirname(runtime.path))
    push!(tpalist, clrbridge)
    CURRENT_CLR_HOST[] = create_host(CoreCLRHost;tpalist = tpalist)
    post_init()
end

function build_tpalist(dir)
    joinpath.(dir, filter(x->splitext(x)[2] == ".dll", readdir(dir)))
end

function post_init()
    CLRBridge.init(CURRENT_CLR_HOST[])
    init_marshaller()
end

macro Type_str(name)
    :(CLRBridge.GetType($name))
end

end # module