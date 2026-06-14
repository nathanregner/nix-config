use std::cell::Cell as StdCell;

use petgraph::graph::NodeIndex;
use ratatui::layout::Constraint;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Cell;
use tui_treelistview::{ColumnDef, SimpleColumns, TreeGlyphs, TreeLabelRenderer, TreeRowContext};

use crate::ui::GcRootModel;

#[derive(Clone, Copy, PartialEq)]
pub enum PendingAction {
    None,
    Delete,
    Reset,
}

pub struct Label {
    current_row: StdCell<usize>,
    selected_id: StdCell<Option<NodeIndex>>,
    selected_row: StdCell<Option<usize>>,
}

impl Label {
    pub fn new() -> Self {
        Self {
            current_row: StdCell::new(0),
            selected_id: StdCell::new(None),
            selected_row: StdCell::new(None),
        }
    }

    pub fn reset(&self, selected_id: Option<NodeIndex>) {
        self.current_row.set(0);
        self.selected_id.set(selected_id);
        self.selected_row.set(None);
    }
}

impl TreeLabelRenderer<GcRootModel> for Label {
    fn cell<'a>(
        &'a self,
        model: &'a GcRootModel,
        id: NodeIndex,
        ctx: &TreeRowContext,
        glyphs: &TreeGlyphs<'a>,
    ) -> Cell<'a> {
        let name = model.name(id).unwrap_or("");
        let is_marked = model.is_marked(id);

        let mut spans: Vec<Span<'a>> = Vec::new();

        let row = self.current_row.get();
        self.current_row.set(row + 1);

        let is_selected = self.selected_id.get() == Some(id);
        if is_selected {
            self.selected_row.set(Some(row));
        }

        // TODO: dynamic width based on count...
        let line_num = if is_selected {
            format!("{:>3} ", row)
        } else if let Some(sel_row) = self.selected_row.get() {
            let diff = (row as isize - sel_row as isize).abs();
            format!("{:>3} ", diff)
        } else {
            format!("{:>3} ", row)
        };
        spans.push(Span::styled(line_num, Style::default().fg(Color::DarkGray)));

        if ctx.level > 0 && ctx.render.draw_lines {
            for (l, is_last) in ctx.is_tail_stack.iter().enumerate() {
                let part = if l == (ctx.level as usize) - 1 {
                    if *is_last {
                        glyphs.branch_last
                    } else {
                        glyphs.branch
                    }
                } else if *is_last {
                    glyphs.indent
                } else {
                    glyphs.vert
                };
                spans.push(Span::styled(part, ctx.line_style));
            }
        } else if ctx.level > 0 {
            for _ in 0..ctx.level {
                spans.push(Span::raw(glyphs.empty));
            }
        }

        let expander = if ctx.node.has_children {
            if ctx.node.is_expanded {
                glyphs.expanded
            } else {
                glyphs.collapsed
            }
        } else if ctx.level == 0 {
            ""
        } else {
            // glyphs.leaf
            " "
        };
        if !expander.is_empty() {
            spans.push(Span::raw(expander));
            spans.push(Span::raw(" "));
        }

        let name_style = if is_marked {
            Style::default().add_modifier(Modifier::CROSSED_OUT | Modifier::DIM)
        } else {
            Style::default()
        };
        spans.push(Span::styled(name.to_string(), name_style));

        Cell::from(Line::from(spans))
    }
}

fn marked_style(model: &GcRootModel, id: NodeIndex) -> Style {
    if model.is_marked(id) {
        Style::default().add_modifier(Modifier::CROSSED_OUT | Modifier::DIM)
    } else {
        Style::default()
    }
}

use crate::ui::format_size;

pub fn closure_cell(model: &GcRootModel, id: NodeIndex) -> Cell<'_> {
    let size = model.closure_size(id);
    if size == 0 {
        Cell::from("")
    } else {
        Cell::from(format_size(size)).style(marked_style(model, id))
    }
}

pub fn added_cell(model: &GcRootModel, id: NodeIndex) -> Cell<'_> {
    let size = model.added_size(id);
    if size == 0 {
        Cell::from("")
    } else {
        Cell::from(format_size(size)).style(marked_style(model, id))
    }
}

pub fn make_columns() -> SimpleColumns<2, GcRootModel> {
    SimpleColumns::new(
        Constraint::Fill(1),
        "Name",
        [
            ColumnDef::new("Closure", Constraint::Length(8), closure_cell),
            ColumnDef::new("Added", Constraint::Length(8), added_cell),
        ],
    )
    .header_style(
        Style::default()
            .fg(Color::Yellow)
            .add_modifier(Modifier::BOLD),
    )
}
