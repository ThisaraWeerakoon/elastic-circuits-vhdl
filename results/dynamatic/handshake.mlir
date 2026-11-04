module {
  handshake.func @elasticflow(%x: memref<64xi32>, %x_start: <>, %start: <>) -> (out0: <i32>, x_end: <>, end: <>) {
    %ldData, %memEnd = mem_controller[%x : memref<64xi32>] start(%x_start) groups(bb1: [load(%addressResult)]) end(%result_4) {handshake.name = "mem_controller0"} : <i32>, <i32>   
    %0 = constant %start {handshake.bb = 0 : ui32, handshake.name = "constant0", value = 0 : i32} : <>, <i32>
    %1 = constant %start {handshake.bb = 0 : ui32, handshake.name = "constant1", value = 1 : i32} : <>, <i32>
    %2 = br %0 {handshake.bb = 0 : ui32, handshake.name = "br0"} : <i32>
    %3 = br %1 {handshake.bb = 0 : ui32, handshake.name = "br1"} : <i32>
    %4 = br %start {handshake.bb = 0 : ui32, handshake.name = "br2"} : <>
    %5 = mux %index [%2, %trueResult] {handshake.bb = 1 : ui32, handshake.name = "mux0"} : <i1>, [<i32>, <i32>] to <i32>
    %6 = mux %index [%3, %trueResult_0] {handshake.bb = 1 : ui32, handshake.name = "mux1"} : <i1>, [<i32>, <i32>] to <i32>
    %result, %index = control_merge [%4, %trueResult_2]  {handshake.bb = 1 : ui32, handshake.name = "control_merge0"} : [<>, <>] to <>, <i1>
    %7 = source {handshake.bb = 1 : ui32, handshake.name = "source0"} : <>
    %8 = constant %7 {handshake.bb = 1 : ui32, handshake.name = "constant2", value = 64 : i32} : <>, <i32>
    %9 = source {handshake.bb = 1 : ui32, handshake.name = "source1"} : <>
    %10 = constant %9 {handshake.bb = 1 : ui32, handshake.name = "constant3", value = 1 : i32} : <>, <i32>
    %11 = source {handshake.bb = 1 : ui32, handshake.name = "source2"} : <>
    %12 = constant %11 {handshake.bb = 1 : ui32, handshake.name = "constant4", value = 0 : i32} : <>, <i32>
    %13 = extui %5 {handshake.bb = 1 : ui32, handshake.name = "extui0"} : <i32> to <i64>
    %14 = trunci %13 {handshake.bb = 1 : ui32, handshake.name = "trunci0"} : <i64> to <i32>
    %addressResult, %dataResult = load[%14] %ldData {handshake.bb = 1 : ui32, handshake.name = "load0"} : <i32>, <i32>, <i32>, <i32>
    %15 = cmpi sgt, %dataResult, %12 {handshake.bb = 1 : ui32, handshake.name = "cmpi0"} : <i32>
    %16 = muli %6, %dataResult {handshake.bb = 1 : ui32, handshake.name = "muli0"} : <i32>
    %17 = addi %6, %dataResult {handshake.bb = 1 : ui32, handshake.name = "addi0"} : <i32>
    %18 = select %15[%16, %17] {handshake.bb = 1 : ui32, handshake.name = "select0"} : <i1>, <i32>
    %19 = addi %5, %10 {handshake.bb = 1 : ui32, handshake.name = "addi1"} : <i32>
    %20 = cmpi ult, %19, %8 {handshake.bb = 1 : ui32, handshake.name = "cmpi1"} : <i32>
    %trueResult, %falseResult = cond_br %20, %19 {handshake.bb = 1 : ui32, handshake.name = "cond_br0"} : <i1>, <i32>
    %trueResult_0, %falseResult_1 = cond_br %20, %18 {handshake.bb = 1 : ui32, handshake.name = "cond_br1"} : <i1>, <i32>
    %trueResult_2, %falseResult_3 = cond_br %20, %result {handshake.bb = 1 : ui32, handshake.name = "cond_br2"} : <i1>, <>
    %21 = merge %falseResult_1 {handshake.bb = 2 : ui32, handshake.name = "merge0"} : <i32>
    %result_4, %index_5 = control_merge [%falseResult_3]  {handshake.bb = 2 : ui32, handshake.name = "control_merge1"} : [<>] to <>, <i1>
    end {handshake.bb = 2 : ui32, handshake.name = "end0"} %21, %memEnd, %start : <i32>, <>, <>
  }
}

