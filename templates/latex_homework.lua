return {
    name = "LaTeX Homework",
    ext = "tex",
    content = function(filename, dir)
        local date_str = os.date("%m/%d/%Y")

        return {
            "\\documentclass[12pt, a4paper]{article}",
            "\\usepackage[utf8]{inputenc}",
            "\\usepackage{geometry}",
            "\\usepackage{amsmath}",
            "\\geometry{top=1in, bottom=1in, left=1in, right=1in}",
            "\\setlength{\\parindent}{0pt}",
            "",
            "\\begin{document}",
            "",
            "\\noindent",
            "\\textbf{Name:} Mark Joseph D. Amarille \\\\",
            "\\textbf{Section:} CS3201 \\\\",
            "\\textbf{Date:} " .. date_str .. " \\\\",
            "\\textbf{Subject:} Game Programming \\\\",
            "\\textbf{Course Code:} IT2107",
            "",
            "\\vspace{0.5cm}",
            "",
            "\\begin{center}",
            "    \\Large \\textbf{" .. filename .. "}",
            "\\end{center}",
            "",
            "$CURSOR",
            "",
            "\\end{document}",
        }
    end,
}
