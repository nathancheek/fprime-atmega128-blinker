module LedBlinker {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup10Hz
      rateGroup1Hz
    }

  deployment topology LedBlinkerDeployment {

    # ----------------------------------------------------------------------
    # Subtopology imports
    # ----------------------------------------------------------------------


    import ComCcsds.Subtopology

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance cmdDisp
    instance comDriver
    instance eventLogger
    instance fatalHandler
    instance rateDriver
    instance rateGroup10Hz
    instance rateGroup1Hz
    instance rateGroupDriver
    instance timeHandler
    instance tlmSend
    instance led
    instance gpioDriver

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance cmdDisp

    event connections instance eventLogger

    telemetry connections instance tlmSend

    time connections instance timeHandler

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections RateGroups {
      # Timer1 overflow-based interrupt. Rate groups run from the main loop.
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # 10 Hz rate group: poll the ground UART for uplink
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup10Hz] -> rateGroup10Hz.CycleIn
      rateGroup10Hz.RateGroupMemberOut[0] -> comDriver.schedIn
      # Send a partly filled TM frame instead of waiting for it to fill
      rateGroup10Hz.RateGroupMemberOut[1] -> ComCcsds.aggregator.timeout

      # 1 Hz rate group: keep downlink traffic low enough for the ComQueue to keep up
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup1Hz] -> rateGroup1Hz.CycleIn
      rateGroup1Hz.RateGroupMemberOut[0] -> tlmSend.Run
      rateGroup1Hz.RateGroupMemberOut[1] -> cmdDisp.run
    }

    connections FaultProtection {
      eventLogger.FatalAnnounce -> fatalHandler.FatalReceive
    }


    connections Communications {
      # Inputs to ComQueue (events, telemetry, file)
      eventLogger.PktSend -> ComCcsds.comQueue.comPacketQueueIn[ComCcsds.Ports_ComPacketQueue.EVENTS]
      tlmSend.PktSend     -> ComCcsds.comQueue.comPacketQueueIn[ComCcsds.Ports_ComPacketQueue.TELEMETRY]

      # ComDriver buffer allocations
      comDriver.allocate      -> ComCcsds.commsBufferManager.bufferGetCallee
      comDriver.deallocate    -> ComCcsds.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      comDriver.$recv                     -> ComCcsds.comStub.drvReceiveIn
      ComCcsds.comStub.drvReceiveReturnOut -> comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      ComCcsds.comStub.drvSendOut      -> comDriver.$send
      comDriver.ready         -> ComCcsds.comStub.drvConnected

      # Router <-> CmdDispatcher
      ComCcsds.fprimeRouter.commandOut  -> cmdDisp.seqCmdBuff
      cmdDisp.seqCmdStatus     -> ComCcsds.fprimeRouter.cmdResponseIn
    }

    connections LedBlinkerDeployment {
      # Add here connections to user-defined components
      # Rate Group 1Hz output is connected to led's run input
      rateGroup1Hz.RateGroupMemberOut[2] -> led.run
      # led's gpioSet output is connected to gpioDriver's gpioWrite input
      led.gpioSet -> gpioDriver.gpioWrite
    }

  }

}
