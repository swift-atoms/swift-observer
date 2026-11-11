#if Tracking
    @attached(member, names: named(_$registrar))
    @attached(extension, conformances: Observable)
    @attached(memberAttribute)
    public macro Observable() =
        #externalMacro(
            module: "Observer_Macros",
            type: "ObservableMacro"
        )
#endif
