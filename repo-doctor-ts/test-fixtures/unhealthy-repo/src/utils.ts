// TODO: refactor this function to be more efficient
export function slowSort(arr: number[]): number[] {
  // FIXME: this is O(n^2), should use a better algorithm
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] > arr[j]) {
        [arr[i], arr[j]] = [arr[j], arr[i]];
      }
    }
  }
  return arr;
}

// HACK: temporary workaround for date parsing bug
export function parseDate(str: string): Date {
  return new Date(str);
}

// XXX: this needs proper error handling
export function divide(a: number, b: number): number {
  return a / b;
}
