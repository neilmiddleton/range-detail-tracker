enum ButtRegisterBuilder {
    static func rows(for session: Session) -> [ButtRegisterRow] {
        session.details
            .sorted { $0.sequenceNumber < $1.sequenceNumber }
            .flatMap { detail in
                detail.firings
                    .sorted { $0.laneNumber < $1.laneNumber }
                    .compactMap { firing -> ButtRegisterRow? in
                        guard let cadet = session.cadets.first(where: { $0.id == firing.cadetID }),
                              let practice = session.practices.first(where: { $0.id == firing.practiceID })
                        else { return nil }
                        return ButtRegisterRow(
                            detailSequenceNumber: detail.sequenceNumber,
                            laneNumber: firing.laneNumber,
                            cadetName: cadet.name,
                            practiceName: practice.name,
                            score: firing.score,
                            esScore: firing.esScore,
                            pvScore: firing.pvScore,
                            outcome: firing.outcome
                        )
                    }
            }
    }
}
