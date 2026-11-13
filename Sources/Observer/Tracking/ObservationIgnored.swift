#if Tracking
    @attached(peer)
    public macro ObservationIgnored() =
        #externalMacro(
            module: "Observer_Macros",
            type: "Ignored"
        )
#endif
