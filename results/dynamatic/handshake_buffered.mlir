module {
  handshake.func @elasticflow(%x: memref<64xi32>, %x_start: <>, %start: <>) -> (out0: <i32>, x_end: <>, end: <>) attributes {handshake.cfdfcThroughput = #handshake<cfdfcThroughput {"0" = 2.500000e-01 : f64}>, handshake.cfdfcToBBList = #handshake<cfdfcToBBList {"0" = [1 : ui32]}>} {
    %0:4 = fork [4] %start {handshake.bb = 0 : ui32, handshake.bufProps = #handshake<bufProps{"0": [0,0], [0,0], 0, 0.000000e+00, 0.000000e+00, 0.000000e+00}>, handshake.name = "fork0"} : <>
    %ldData, %memEnd = mem_controller[%x : memref<64xi32>] start(%x_start) groups(bb1: [load(%addressResult)]) end(%result_4) {handshake.bufProps = #handshake<bufProps{"0": [0,0], [0,0], 0, 0.000000e+00, 0.000000e+00, 0.000000e+00, "1": [0,0], [0,0], 0, 0.000000e+00, 0.000000e+00, 0.000000e+00, "2": [0,0], [0,0], 0, 0.000000e+00, 0.000000e+00, 0.000000e+00}>, handshake.name = "mem_controller1"} : <i6>, <i32>   
    %1 = constant %0#0 {handshake.bb = 0 : ui32, handshake.name = "constant5", value = false} : <>, <i1>
    %2 = br %1 {handshake.bb = 0 : ui32, handshake.name = "br0"} : <i1>
    %3 = extui %2 {handshake.bb = 1 : ui32, handshake.name = "extui1"} : <i1> to <i6>
    %4 = constant %0#1 {handshake.bb = 0 : ui32, handshake.name = "constant6", value = true} : <>, <i1>
    %5 = br %4 {handshake.bb = 0 : ui32, handshake.name = "br1"} : <i1>
    %6 = extui %5 {handshake.bb = 0 : ui32, handshake.name = "extui2"} : <i1> to <i32>
    %7 = br %0#3 {handshake.bb = 0 : ui32, handshake.name = "br2"} : <>
    %8 = mux %18#0 [%3, %trueResult] {handshake.bb = 1 : ui32, handshake.name = "mux0"} : <i1>, [<i6>, <i6>] to <i6>
    %9 = buffer %8, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer0"} : <i6>
    %10 = buffer %9, bufferType = ONE_SLOT_BREAK_R, numSlots = 1, dvLatency = 0 {handshake.bb = 1 : ui32, handshake.name = "buffer1"} : <i6>
    %11:2 = fork [2] %10 {handshake.bb = 1 : ui32, handshake.name = "fork1"} : <i6>
    %12 = extui %11#1 {handshake.bb = 1 : ui32, handshake.name = "extui3"} : <i6> to <i7>
    %13 = constant %20 {handshake.bb = 1 : ui32, handshake.name = "constant7", value = 1 : i7} : <>, <i7>
    %14 = buffer %18#1, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer5"} : <i1>
    %15 = mux %14 [%6, %trueResult_0] {handshake.bb = 1 : ui32, handshake.name = "mux1"} : <i1>, [<i32>, <i32>] to <i32>
    %16 = buffer %15, bufferType = ONE_SLOT_BREAK_R, numSlots = 1, dvLatency = 0 {handshake.bb = 1 : ui32, handshake.name = "buffer2"} : <i32>
    %17:2 = fork [2] %16 {handshake.bb = 1 : ui32, handshake.name = "fork2"} : <i32>
    %result, %index = control_merge [%7, %trueResult_2]  {handshake.bb = 1 : ui32, handshake.name = "control_merge0"} : [<>, <>] to <>, <i1>
    %18:2 = fork [2] %index {handshake.bb = 1 : ui32, handshake.name = "fork3"} : <i1>
    %19 = source {handshake.bb = 1 : ui32, handshake.name = "source0"} : <>
    %20 = source {handshake.bb = 1 : ui32, handshake.name = "source1"} : <>
    %21 = source {handshake.bb = 1 : ui32, handshake.name = "source2"} : <>
    %22 = constant %21 {handshake.bb = 1 : ui32, handshake.name = "constant4", value = 0 : i32} : <>, <i32>
    %addressResult, %dataResult = load[%11#0] %ldData {handshake.bb = 1 : ui32, handshake.bufProps = #handshake<bufProps{"1": [0,0], [0,0], 0, 0.000000e+00, 0.000000e+00, 0.000000e+00}>, handshake.mem_interface = #handshake.mem_interface<MC>, handshake.name = "load0"} : <i6>, <i32>, <i6>, <i32>
    %23:3 = fork [3] %dataResult {handshake.bb = 1 : ui32, handshake.name = "fork4"} : <i32>
    %24 = cmpi sgt, %23#0, %22 {handshake.bb = 1 : ui32, handshake.name = "cmpi0"} : <i32>
    %25 = muli %17#1, %23#1 {handshake.bb = 1 : ui32, handshake.name = "muli0", latency = 4 : i64} : <i32>
    %26 = buffer %17#0, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer3"} : <i32>
    %27 = buffer %23#2, bufferType = FIFO_BREAK_NONE, numSlots = 1, dvLatency = 0 {handshake.bb = 1 : ui32, handshake.name = "buffer6"} : <i32>
    %28 = addi %26, %27 {handshake.bb = 1 : ui32, handshake.name = "addi0"} : <i32>
    %29 = buffer %24, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer7"} : <i1>
    %30 = buffer %28, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer8"} : <i32>
    %31 = select %29[%25, %30] {antitokenDepth = 1 : i64, handshake.bb = 1 : ui32, handshake.name = "select0"} : <i1>, <i32>
    %32 = addi %12, %13 {handshake.bb = 1 : ui32, handshake.name = "addi1"} : <i7>
    %33 = buffer %32, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer9"} : <i7>
    %34:2 = fork [2] %33 {handshake.bb = 1 : ui32, handshake.name = "fork5"} : <i7>
    %35 = trunci %34#0 {handshake.bb = 1 : ui32, handshake.name = "trunci1"} : <i7> to <i6>
    %36 = constant %19 {handshake.bb = 1 : ui32, handshake.name = "constant8", value = -64 : i7} : <>, <i7>
    %37 = cmpi ult, %34#1, %36 {handshake.bb = 1 : ui32, handshake.name = "cmpi1"} : <i7>
    %38:3 = fork [3] %37 {handshake.bb = 1 : ui32, handshake.name = "fork6"} : <i1>
    %trueResult, %falseResult = cond_br %38#0, %35 {handshake.bb = 1 : ui32, handshake.name = "cond_br0"} : <i1>, <i6>
    sink %falseResult {handshake.name = "sink0"} : <i6>
    %39 = buffer %38#1, bufferType = FIFO_BREAK_NONE, numSlots = 1, dvLatency = 0 {handshake.bb = 1 : ui32, handshake.name = "buffer10"} : <i1>
    %trueResult_0, %falseResult_1 = cond_br %39, %31 {handshake.bb = 1 : ui32, handshake.name = "cond_br1"} : <i1>, <i32>
    %40 = buffer %result, bufferType = ONE_SLOT_BREAK_DV, numSlots = 1, dvLatency = 1 {handshake.bb = 1 : ui32, handshake.name = "buffer4"} : <>
    %trueResult_2, %falseResult_3 = cond_br %38#2, %40 {handshake.bb = 1 : ui32, handshake.name = "cond_br2"} : <i1>, <>
    %41 = merge %falseResult_1 {handshake.bb = 2 : ui32, handshake.name = "merge0"} : <i32>
    %result_4, %index_5 = control_merge [%falseResult_3]  {handshake.bb = 2 : ui32, handshake.name = "control_merge1"} : [<>] to <>, <i1>
    sink %index_5 {handshake.name = "sink1"} : <i1>
    end {handshake.bb = 2 : ui32, handshake.name = "end0"} %41, %memEnd, %0#2 : <i32>, <>, <>
  }
}

