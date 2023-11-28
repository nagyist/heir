#include <utility>

#include "mlir/include/mlir/Dialect/Affine/Analysis/AffineAnalysis.h"  // from @llvm-project
#include "mlir/include/mlir/Dialect/Affine/IR/AffineOps.h"  // from @llvm-project
#include "mlir/include/mlir/Dialect/Affine/IR/AffineValueMap.h"  // from @llvm-project

namespace mlir {
namespace heir {

using ::llvm::ArrayRef;

std::optional<std::vector<uint64_t>> materialize(affine::MemRefAccess access) {
  affine::AffineValueMap thisMap;
  access.getAccessMap(&thisMap);
  std::vector<uint64_t> accessIndices;
  for (auto i = 0; i < access.getRank(); ++i) {
    // The access indices of the global memref *must* be constant,
    // meaning that they cannot be a variable access (for example, a
    // loop index) or symbolic, for example, an input symbol.
    auto affineValue = thisMap.getResult(i);
    if (affineValue.getKind() != AffineExprKind::Constant) {
      return std::nullopt;
    }
    accessIndices.push_back(
        (thisMap.getResult(i).dyn_cast<mlir::AffineConstantExpr>()).getValue());
  }

  return std::move(accessIndices);
}

// getFlattenedAccessIndex gets the flattened access index for MemRef access
// given the MemRef type's shape. Returns a std::nullopt if the indices are not
// constants (e.g. derived from inputs).
std::optional<uint64_t> getFlattenedAccessIndex(affine::MemRefAccess access,
                                                mlir::Type memRefType) {
  auto accessIndices = materialize(access);
  if (!accessIndices.has_value()) {
    return std::nullopt;
  }
  return mlir::ElementsAttr::getFlattenedIndex(
      memRefType, llvm::ArrayRef<uint64_t>(accessIndices.value()));
}

llvm::SmallVector<int64_t> unflattenIndex(int64_t index,
                                          const llvm::ArrayRef<int64_t> strides,
                                          int64_t offset) {
  llvm::SmallVector<int64_t> indices;
  int64_t ndx = index - offset;
  for (int i = 0; i < strides.size(); ++i) {
    indices.push_back(ndx / strides[i]);
    ndx = ndx % strides[i];
  }
  return indices;
}

int64_t flattenIndex(const llvm::ArrayRef<int64_t> indices,
                     const llvm::ArrayRef<int64_t> strides, int64_t offset) {
  int64_t index = offset;
  for (int i = 0; i < strides.size(); ++i) {
    index += indices[i] * strides[i];
  }
  return index;
}

}  // namespace heir
}  // namespace mlir
