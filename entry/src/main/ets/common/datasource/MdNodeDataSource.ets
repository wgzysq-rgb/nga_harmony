import { MdNode } from '../../model/MdNode'
import { BaseLazyDataSource } from './BaseLazyDataSource'

/**
 * Markdown AST 节点懒加载数据源。
 *
 * 用于 MdContentView 在长内容（≥20 个块级节点）时
 * 切换到 LazyForEach 虚拟滚动，减少组件实例数。
 */
export class MdNodeDataSource extends BaseLazyDataSource<MdNode> {
}
