// RUN: heir-opt --openfhe-configure-crypto-context=entry-function=simple_sum %s | FileCheck %s

#encoding = #lwe.polynomial_evaluation_encoding<cleartext_start = 16, cleartext_bitwidth = 16>
#ideal = #_polynomial.polynomial<1 + x**32>
#params = #lwe.rlwe_params<ring = <cmod=463187969, ideal=#ideal>>
!in_ty = !lwe.rlwe_ciphertext<encoding = #encoding, rlwe_params = #params, underlying_type = tensor<32xi16>>
!out_ty = !lwe.rlwe_ciphertext<encoding = #encoding, rlwe_params = #params, underlying_type = i16>
!ctxt_ty = !openfhe.crypto_context
!plain_ty = !lwe.rlwe_plaintext<encoding = #encoding, ring = <cmod=463187969, ideal=#_polynomial.polynomial<1 + x**32>>, underlying_type = tensor<32xi16>>

func.func @simple_sum(%arg0: !ctxt_ty, %arg1: !in_ty) -> !out_ty {
  %c31_i64 = arith.constant 31 : i64
  %c1_i64 = arith.constant 1 : i64
  %c2_i64 = arith.constant 2 : i64
  %c4_i64 = arith.constant 4 : i64
  %c8_i64 = arith.constant 8 : i64
  %cst = arith.constant dense<[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]> : tensor<32xi16>
  %c16_i64 = arith.constant 16 : i64
  %0 = openfhe.rot %arg0, %arg1, %c16_i64 : (!ctxt_ty, !in_ty, i64) -> !in_ty
  %1 = openfhe.add %arg0, %arg1, %0 : (!ctxt_ty, !in_ty, !in_ty) -> !in_ty
  %2 = openfhe.rot %arg0, %1, %c8_i64 : (!ctxt_ty, !in_ty, i64) -> !in_ty
  %3 = openfhe.add %arg0, %1, %2 : (!ctxt_ty, !in_ty, !in_ty) -> !in_ty
  %4 = openfhe.rot %arg0, %3, %c4_i64 : (!ctxt_ty, !in_ty, i64) -> !in_ty
  %5 = openfhe.add %arg0, %3, %4 : (!ctxt_ty, !in_ty, !in_ty) -> !in_ty
  %6 = openfhe.rot %arg0, %5, %c2_i64 : (!ctxt_ty, !in_ty, i64) -> !in_ty
  %7 = openfhe.add %arg0, %5, %6 : (!ctxt_ty, !in_ty, !in_ty) -> !in_ty
  %8 = openfhe.rot %arg0, %7, %c1_i64 : (!ctxt_ty, !in_ty, i64) -> !in_ty
  %9 = openfhe.add %arg0, %7, %8 : (!ctxt_ty, !in_ty, !in_ty) -> !in_ty
  %10 = lwe.rlwe_encode %cst {encoding = #encoding, ring = #_polynomial.ring<cmod=463187969, ideal=#ideal>} : tensor<32xi16> -> !plain_ty
  %11 = openfhe.mul_plain %arg0, %9, %10 : (!ctxt_ty, !in_ty, !plain_ty) -> !in_ty
  %12 = openfhe.rot %arg0, %11, %c31_i64 : (!ctxt_ty, !in_ty, i64) -> !in_ty
  %13 = lwe.reinterpret_underlying_type %12 : !in_ty to !out_ty
  return %13 : !out_ty
}

// CHECK-LABEL: @simple_sum
// CHECK: @simple_sum__generate_crypto_context
// CHECK: @simple_sum__configure_crypto_context
