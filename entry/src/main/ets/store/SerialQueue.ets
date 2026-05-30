export class SerialQueue {
  private last: Promise<void> = Promise.resolve()

  enqueue(fn: () => Promise<void>): Promise<void> {
    this.last = this.last.then((): Promise<void> => fn()).catch((): void => {
      console.error('SerialQueue: a task failed, chain continued')
    })
    return this.last
  }
}
