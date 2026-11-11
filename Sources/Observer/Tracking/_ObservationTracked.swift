#if Tracking
    @attached(accessor, names: named(init), named(_read), named(_modify))
    @attached(peer, names: prefixed(_))
    public macro _ObservationTracked(_ id: UInt32 = 0) =
        #externalMacro(
            module: "Observer_Macros",
            type: "Tracked"
        )
#endif
