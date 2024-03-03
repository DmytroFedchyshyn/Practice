
public without sharing class ParenthesesValidator {

    public Boolean validate(String str){
        List<String> strings = str.split('');
        if (!strings.isEmpty()) {
            return validateInner(strings);
        }
        return false;
    }

    private Boolean validateInner(List<String> strings) {
        Map<String, String> parentheses = new Map<String, String>{
                '{' => '}',
                '[' => ']',
                '(' => ')'
        };
        if (!strings.isEmpty() && Math.mod( strings.size(), 2) == 0) {
            String open = strings.remove(0);
            String close = strings.remove(strings.size() - 1);
            if (parentheses.containsKey(open) && parentheses.get(open).equals(close)) {
                return validateInner(strings);
            } else {
                return false;
            }
        }
        return true;
    }

        public Boolean validate2(String str) {
            if (String.isEmpty(str) || Math.mod(str.length(), 2) != 0) {
                return false;
            }

            Map<String, String> parentheses = new Map<String, String>{
                    '}' => '{',
                    ']' => '[',
                    ')' => '('
            };

            List<String> stack = new List<String>();

            for (Integer i = 0; i < str.length(); i++) {
                String currentChar = str.substring(i, i + 1);
                if (parentheses.values().contains(currentChar)) {
                    stack.add(currentChar);
                } else if (stack.isEmpty() || stack.remove(stack.size() - 1) != parentheses.get(currentChar)) {
                    return false;
                }
            }

            return stack.isEmpty();
        }

}