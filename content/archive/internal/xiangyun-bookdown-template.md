---
title: "中文书籍的 bookdown 模版"
author: "黄湘云"
date: "2022-01-08T07:51:02Z"
link: "https://bookdown.org/xiangyun/bookdown-template/"
length_weight: "3.9%"
repo: "XiangyunHuang/bookdown-template"
pinned: false
---

这是一个简单的中文书籍模版，顺便介绍了如何使用中英文字体，参考文献样式等。 [...] 这是中文书籍模版，源文件的编译和组织使用 knitr (Xie 2015) 和 bookdown (Xie 2016)，参考文献的样式文件来自 Zotero。 系统上安装 Noto 系列的四款字体，依次是英文衬线字体，英文无衬线字体，简体中文宋体，简体中文黑体，其中，两款英文字体包含正常、粗体、斜体、粗斜体四种字型。 安装后，需要先调用 sysfonts 包注册字体到 R 环境，以便绘图时使用。 showtext 包调用系统安装的中英文字体，如图 0.1 所示，横纵坐标轴标题使用黑体，主标题黑体加粗，边空文本是宋体，图内注释也是宋体，坐标轴刻度值用无衬线字体。 本书使用 Bootstrap 样式主题，因此，除了 ...
