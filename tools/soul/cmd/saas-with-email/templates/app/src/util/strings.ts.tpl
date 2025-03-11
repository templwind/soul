/**
 * Cuts the string from the first occurrence of a pattern and returns the second part, trimmed of whitespace.
 */
export function cutStringFromMatch(input: string, pattern: string): string {
  console.log(input);
  const parts = input.split(pattern);
  if (parts.length < 2) {
    return input;
  }
  return parts[1].trim();
}

/**
 * Converts a string into camelCase.
 */
export function toCamel(s: string): string {
  const words = splitIntoWords(s);
  for (let i = 0; i < words.length; i++) {
    if (i == 0) {
      words[i] = words[i].toLowerCase();
    } else {
      words[i] = titleCase(words[i]);
    }
  }
  return words.join("");
}

/**
 * Converts a string into kebab-case by joining words with a hyphen.
 */
export function toKebab(s: string): string {
  return splitIntoWords(s).join("-");
}

/**
 * Converts a string into Title Case by capitalizing the first letter of each word.
 */
export function toTitle(s: string): string {
  const words = splitIntoWords(s);
  for (let i = 0; i < words.length; i++) {
    if (words[i].length > 0) {
      words[i] = firstToUpper(words[i]);
    }
  }
  return words.join(" ");
}

/**
 * Converts a string into snake_case by joining words with an underscore.
 */
export function toSnake(s: string): string {
  return splitIntoWords(s).join("_");
}

/**
 * Converts a string into PascalCase by capitalizing the first letter of each word and joining them.
 */
export function toPascal(s: string): string {
  const words = splitIntoWords(s);
  for (let i = 0; i < words.length; i++) {
    words[i] = firstToUpper(words[i]);
  }
  return words.join("");
}

/**
 * Converts a string into CONSTANT_CASE by joining words with an underscore and converting the entire string to uppercase.
 */
export function toConstant(s: string): string {
  return splitIntoWords(s).join("_").toUpperCase();
}

/**
 * Splits a string into an array of words based on non-alphanumeric characters using a regular expression.
 */
export function splitIntoWords(s: string): string[] {
  return s.split(/[^a-zA-Z0-9]+/);
}

/**
 * Converts the first character of a string to lowercase.
 */
export function firstToLower(s: string): string {
  if (s.length === 0) {
    return s;
  }
  const firstRune = s.charAt(0);
  return firstRune.toLowerCase() + s.slice(1);
}

/**
 * Converts the first character of a string to uppercase.
 */
export function firstToUpper(s: string): string {
  if (s.length === 0) {
    return s;
  }
  const firstRune = s.charAt(0);
  return firstRune.toUpperCase() + s.slice(1);
}

/**
 * Converts each word to title case (first character uppercase, rest lowercase).
 */
export function titleCase(s: string): string {
  if (s.length === 0) {
    return s;
  }
  const words = s.split(" ");
  return words.map((word) => firstToUpper(word.toLowerCase())).join(" ");
}
