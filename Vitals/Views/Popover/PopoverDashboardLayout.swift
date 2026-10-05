import SwiftUI

/// Measures the cards at their actual font size, then uses the fewest columns
/// that fit below the menu bar. Section order runs down each column in turn.
struct PopoverDashboardLayout: Layout {
    let maximumSize: CGSize
    let textScale: Double

    private let padding: CGFloat = 10
    private let spacing: CGFloat = 8

    struct Plan {
        let size: CGSize
        let headerHeight: CGFloat
        let columnWidth: CGFloat
        let columns: [Range<Int>]
        let cardHeights: [CGFloat]
    }

    typealias Cache = Plan?

    func makeCache(subviews: Subviews) -> Cache { nil }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let plan = measure(subviews)
        cache = plan
        return plan.size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache
    ) {
        let plan = cache ?? measure(subviews)
        guard let header = subviews.first else { return }
        header.place(
            at: CGPoint(x: bounds.minX + padding, y: bounds.minY + padding),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: plan.size.width - 2 * padding, height: plan.headerHeight)
        )

        for (columnIndex, range) in plan.columns.enumerated() {
            let x = bounds.minX + padding + CGFloat(columnIndex) * (plan.columnWidth + spacing)
            var y = bounds.minY + padding + plan.headerHeight + spacing
            for cardIndex in range {
                subviews[cardIndex + 1].place(
                    at: CGPoint(x: x, y: y), anchor: .topLeading,
                    proposal: ProposedViewSize(width: plan.columnWidth, height: plan.cardHeights[cardIndex])
                )
                y += plan.cardHeights[cardIndex] + spacing
            }
        }
    }

    private func measure(_ subviews: Subviews) -> Plan {
        guard let header = subviews.first else {
            return Plan(size: .zero, headerHeight: 0, columnWidth: 0, columns: [], cardHeights: [])
        }
        let availableWidth = max(1, maximumSize.width - 2 * padding)
        let preferredWidth = min(280 * max(1, textScale), availableWidth)
        let cardCount = subviews.count - 1
        let maximumColumns = max(1, min(cardCount, Int((availableWidth + spacing) / (260 + spacing))))
        var shortest: Plan?

        for columnCount in 1...maximumColumns {
            let columnWidth = min(
                preferredWidth, (availableWidth - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
            )
            let width = CGFloat(columnCount) * columnWidth + CGFloat(columnCount - 1) * spacing
            let headerHeight = header.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            let cardHeights = subviews.dropFirst().map {
                $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height
            }
            let columns = balancedColumns(heights: cardHeights, count: columnCount)
            let columnHeight = columns.map { height(of: $0, in: cardHeights) }.max() ?? 0
            let plan = Plan(
                size: CGSize(
                    width: width + 2 * padding,
                    height: headerHeight + (cardCount > 0 ? spacing + columnHeight : 0) + 2 * padding),
                headerHeight: headerHeight, columnWidth: columnWidth,
                columns: columns, cardHeights: cardHeights
            )
            if plan.size.height <= maximumSize.height { return plan }
            if shortest == nil || plan.size.height < shortest!.size.height { shortest = plan }
        }
        // The caller keeps a scroll fallback for unusually small displays.
        return shortest!
    }

    private func height(of range: Range<Int>, in heights: [CGFloat]) -> CGFloat {
        heights[range].reduce(0, +) + CGFloat(max(0, range.count - 1)) * spacing
    }

    /// At most nine cards: checking the contiguous partitions is inexpensive
    /// and keeps the saved section order intact while balancing the columns.
    private func balancedColumns(heights: [CGFloat], count: Int) -> [Range<Int>] {
        guard !heights.isEmpty else { return [] }
        var best: [Range<Int>] = []
        var bestHeight = CGFloat.infinity

        func search(start: Int, remaining: Int, ranges: [Range<Int>], tallest: CGFloat) {
            if remaining == 1 {
                let range = start..<heights.count
                let candidateHeight = max(tallest, height(of: range, in: heights))
                if candidateHeight < bestHeight {
                    bestHeight = candidateHeight
                    best = ranges + [range]
                }
                return
            }
            for end in (start + 1)...(heights.count - remaining + 1) {
                let range = start..<end
                let candidateHeight = max(tallest, height(of: range, in: heights))
                if candidateHeight < bestHeight {
                    search(
                        start: end, remaining: remaining - 1, ranges: ranges + [range], tallest: candidateHeight
                    )
                }
            }
        }
        search(start: 0, remaining: count, ranges: [], tallest: 0)
        return best
    }
}
