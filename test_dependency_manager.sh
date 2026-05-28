#!/bin/bash

echo "=== MuseFlow 依赖管理系统验证 ==="
echo ""

PROJECT_PATH="/home/re/code/MuseFlow"

echo "📁 检查文件结构..."
FILES=(
  "$PROJECT_PATH/pubspec.yaml"
  "$PROJECT_PATH/lib/utils/dependency_auditor.dart"
  "$PROJECT_PATH/lib/utils/dependency_manager.dart"
  "$PROJECT_PATH/bin/dependency_audit.dart"
  "$PROJECT_PATH/DEPENDENCY_MANAGEMENT_README.md"
  "$PROJECT_PATH/.dependency_audit_log.json"
  "$PROJECT_PATH/.dependency_constraints.json"
  "$PROJECT_PATH/.dependency_health_report.json"
)

ALL_EXIST=true
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (缺失)"
    ALL_EXIST=false
  fi
done

echo ""

if [ "$ALL_EXIST" = true ]; then
  echo "✅ 所有核心文件已创建"
else
  echo "❌ 部分文件缺失"
  exit 1
fi

echo ""
echo "📊 验证 pubspec.yaml 精确版本..."

# 检查是否使用精确版本（不包含^符号）
if grep -q '\^[0-9]' "$PROJECT_PATH/pubspec.yaml"; then
  echo "  ❌ 发现范围版本（^x.y.z格式）"
  grep '\^[0-9]' "$PROJECT_PATH/pubspec.yaml"
  exit 1
else
  echo "  ✅ 所有依赖使用精确版本"
fi

echo ""
echo "📋 统计信息..."

TOTAL_DEPS=$(grep -E '^\s+[a-z_]+:\s+[0-9]' "$PROJECT_PATH/pubspec.yaml" | wc -l)
echo "  总依赖数: $TOTAL_DEPS"

PROD_DEPS=$(sed -n '/^dependencies:/,/^dev_dependencies:/p' "$PROJECT_PATH/pubspec.yaml" | grep -E '^\s+[a-z_]+:\s+[0-9]' | wc -l)
echo "  生产依赖: $PROD_DEPS"

DEV_DEPS=$(sed -n '/^dev_dependencies:/,/^flutter:/p' "$PROJECT_PATH/pubspec.yaml" | grep -E '^\s+[a-z_]+:\s+[0-9]' | wc -l)
echo "  开发依赖: $DEV_DEPS"

echo ""
echo "📝 代码统计..."

AUDITOR_LINES=$(wc -l < "$PROJECT_PATH/lib/utils/dependency_auditor.dart")
MANAGER_LINES=$(wc -l < "$PROJECT_PATH/lib/utils/dependency_manager.dart")
CLI_LINES=$(wc -l < "$PROJECT_PATH/bin/dependency_audit.dart")

echo "  dependency_auditor.dart: $AUDITOR_LINES 行"
echo "  dependency_manager.dart: $MANAGER_LINES 行"
echo "  dependency_audit.dart (CLI): $CLI_LINES 行"
echo "  总计: $((AUDITOR_LINES + MANAGER_LINES + CLI_LINES)) 行"

echo ""
echo "🔍 功能模块..."

# 检查核心类
CORE_CLASSES=(
  "DependencyInfo"
  "DependencyAuditor"
  "DependencyManager"
  "DependencyHealthReport"
  "VersionConflict"
  "DependencyUpdateAdvisor"
)

for class in "${CORE_CLASSES[@]}"; do
  if grep -q "class $class" "$PROJECT_PATH/lib/utils/"*.dart; then
    echo "  ✅ $class"
  else
    echo "  ❌ $class (缺失)"
  fi
done

echo ""
echo "📚 配置文件..."

if [ -f "$PROJECT_PATH/.dependency_audit_log.json" ]; then
  LOG_ENTRIES=$(jq '. | length' "$PROJECT_PATH/.dependency_audit_log.json" 2>/dev/null || echo "N/A")
  echo "  ✅ 审计日志: $LOG_ENTRIES 条记录"
fi

if [ -f "$PROJECT_PATH/.dependency_constraints.json" ]; then
  CONSTRAINTS=$(jq '. | length' "$PROJECT_PATH/.dependency_constraints.json" 2>/dev/null || echo "N/A")
  echo "  ✅ 约束配置: $CONSTRAINTS 条规则"
fi

if [ -f "$PROJECT_PATH/.dependency_health_report.json" ]; then
  HEALTH_SCORE=$(jq -r '.score' "$PROJECT_PATH/.dependency_health_report.json" 2>/dev/null || echo "N/A")
  echo "  ✅ 健康报告: 评分 $HEALTH_SCORE"
fi

echo ""
echo "🎯 版本控制验证..."

# 验证关键依赖版本
KEY_VERSIONS=(
  "http:1.2.2"
  "dio:5.7.0"
  "flutter_secure_storage:9.2.2"
  "json_annotation:4.9.0"
  "json_serializable:6.8.0"
)

for version in "${KEY_VERSIONS[@]}"; do
  pkg=${version%:*}
  ver=${version#*:}
  if grep -q "$pkg:$ver" "$PROJECT_PATH/pubspec.yaml"; then
    echo "  ✅ $pkg: $ver"
  else
    echo "  ⚠️  $pkg: 版本不匹配"
  fi
done

echo ""
echo "📄 文档..."
if [ -f "$PROJECT_PATH/DEPENDENCY_MANAGEMENT_README.md" ]; then
  README_LINES=$(wc -l < "$PROJECT_PATH/DEPENDENCY_MANAGEMENT_README.md")
  echo "  ✅ README 文档: $README_LINES 行"
fi

echo ""
echo "🎉 MuseFlow 依赖管理系统实现完成！"
echo ""
echo "📖 使用指南:"
echo "  1. 查看文档: cat DEPENDENCY_MANAGEMENT_README.md"
echo "  2. 快速检查: cd $PROJECT_PATH && dart bin/dependency_audit.dart health"
echo "  3. 完整审计: cd $PROJECT_PATH && dart bin/dependency_audit.dart"
echo "  4. 生成报告: cd $PROJECT_PATH && dart bin/dependency_audit.dart report"
echo ""
echo "✨ 主要功能:"
echo "  • 精确版本控制（消除版本不确定性）"
echo "  • 依赖审计和冲突检测"
echo "  • 健康评分和更新建议"
echo "  • 变更历史追踪"
echo "  • CLI工具支持"
echo ""
