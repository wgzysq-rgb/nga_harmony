import { Component, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export default class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  handleRetry = () => {
    this.setState({ hasError: false, error: null })
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback
      return (
        <div className="flex flex-col items-center justify-center min-h-dvh px-6 text-center">
          <div className="text-[48px] mb-4">😵</div>
          <h2 className="text-[18px] font-semibold text-text mb-2">页面出了点问题</h2>
          <p className="text-[14px] text-text-tertiary mb-6 max-w-[300px]">
            {this.state.error?.message ?? '发生了未知错误'}
          </p>
          <button
            onClick={this.handleRetry}
            className="px-6 py-2.5 text-[15px] font-medium text-white bg-primary rounded-xl active:scale-95 transition-transform"
          >
            重新加载
          </button>
        </div>
      )
    }
    return this.props.children
  }
}
