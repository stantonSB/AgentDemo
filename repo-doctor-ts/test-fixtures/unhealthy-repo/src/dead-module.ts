// This module is never imported by anything
export function unusedFunction(): void {
  console.log("I am never called");
}

export function anotherUnusedFunction(): string {
  return "also unused";
}
