SELECT
  first_answers.answer_name  AS first_concept_name,
  second_answers.answer_name AS second_concept_name,
  gender.gender              AS gender,
  rag.name                   AS age_group,
  rag.sort_order             AS age_group_sort_order,p.person_id,
  sum(CASE WHEN first_concept.answer IS NOT NULL AND second_concept.answer IS NOT NULL AND p.gender IS NOT NULL THEN 1
      ELSE 0 END)            AS patient_count
FROM
  (SELECT
     ca.answer_concept                                                                AS answer,
     ifnull(answer_concept_short_name.name, answer_concept_fully_specified_name.name) AS answer_name
   FROM concept c
     INNER JOIN concept_datatype cd ON c.datatype_id = cd.concept_datatype_id
     INNER JOIN concept_name question_concept_name ON c.concept_id = question_concept_name.concept_id
                                                      AND question_concept_name.concept_name_type = 'FULLY_SPECIFIED'
                                                      AND
                                                      question_concept_name.voided IS FALSE
     INNER JOIN concept_answer ca ON c.concept_id = ca.concept_id
     INNER JOIN concept_name answer_concept_fully_specified_name
       ON ca.answer_concept = answer_concept_fully_specified_name.concept_id
          AND answer_concept_fully_specified_name.concept_name_type = 'FULLY_SPECIFIED' AND
          answer_concept_fully_specified_name.voided IS FALSE
     LEFT JOIN concept_name answer_concept_short_name ON ca.answer_concept = answer_concept_short_name.concept_id
                                                         AND answer_concept_short_name.concept_name_type = 'SHORT' AND
                                                         answer_concept_short_name.voided IS FALSE
   WHERE question_concept_name.name = 'Non Communicable Disease Set, Non Communicable Disease' AND cd.name = 'Coded'
   UNION
   SELECT
     answer_concept_fully_specified_name.concept_id AS answer,
     answer_concept_fully_specified_name.name       AS answer_name
   FROM concept c
     INNER JOIN concept_datatype cd ON c.datatype_id = cd.concept_datatype_id
     INNER JOIN concept_name question_concept_name ON c.concept_id = question_concept_name.concept_id
                                                      AND question_concept_name.concept_name_type = 'FULLY_SPECIFIED'
                                                      AND
                                                      question_concept_name.voided IS FALSE
     INNER JOIN global_property gp ON gp.property IN ('concept.true', 'concept.false')
     INNER JOIN concept_name answer_concept_fully_specified_name
       ON answer_concept_fully_specified_name.concept_id = gp.property_value
          AND answer_concept_fully_specified_name.concept_name_type = 'FULLY_SPECIFIED' AND
          answer_concept_fully_specified_name.voided IS FALSE
   WHERE question_concept_name.name = 'Non Communicable Disease Set, Non Communicable Disease' AND cd.name = 'Boolean'
   ORDER BY answer_name DESC) first_answers
  INNER JOIN
  (SELECT
     ca.answer_concept                                                                AS answer,
     ifnull(answer_concept_short_name.name, answer_concept_fully_specified_name.name) AS answer_name
   FROM concept c
     INNER JOIN concept_datatype cd ON c.datatype_id = cd.concept_datatype_id
     INNER JOIN concept_name question_concept_name ON c.concept_id = question_concept_name.concept_id
                                                      AND question_concept_name.concept_name_type = 'FULLY_SPECIFIED'
                                                      AND
                                                      question_concept_name.voided IS FALSE
     INNER JOIN concept_answer ca ON c.concept_id = ca.concept_id
     INNER JOIN concept_name answer_concept_fully_specified_name
       ON ca.answer_concept = answer_concept_fully_specified_name.concept_id
          AND answer_concept_fully_specified_name.concept_name_type = 'FULLY_SPECIFIED' AND
          answer_concept_fully_specified_name.voided IS FALSE
     LEFT JOIN concept_name answer_concept_short_name ON ca.answer_concept = answer_concept_short_name.concept_id
                                                         AND answer_concept_short_name.concept_name_type = 'SHORT' AND
                                                         answer_concept_short_name.voided IS FALSE
   WHERE question_concept_name.name = 'Non Communicable Disease Set, Risky Behaviour' AND cd.name = 'Coded'
   UNION
   SELECT
     answer_concept_fully_specified_name.concept_id AS answer,
     answer_concept_fully_specified_name.name       AS answer_name
   FROM concept c
     INNER JOIN concept_datatype cd ON c.datatype_id = cd.concept_datatype_id
     INNER JOIN concept_name question_concept_name ON c.concept_id = question_concept_name.concept_id
                                                      AND question_concept_name.concept_name_type = 'FULLY_SPECIFIED'
                                                      AND
                                                      question_concept_name.voided IS FALSE
     INNER JOIN global_property gp ON gp.property IN ('concept.true', 'concept.false')
     INNER JOIN concept_name answer_concept_fully_specified_name
       ON answer_concept_fully_specified_name.concept_id = gp.property_value
          AND answer_concept_fully_specified_name.concept_name_type = 'FULLY_SPECIFIED' AND
          answer_concept_fully_specified_name.voided IS FALSE
   WHERE question_concept_name.name = 'Non Communicable Disease Set, Risky Behaviour' AND cd.name = 'Boolean'
   ORDER BY answer_name DESC
  ) second_answers
  INNER JOIN (SELECT 'M' AS gender
              UNION SELECT 'F' AS gender
              UNION SELECT 'O' AS gender) gender
  INNER JOIN reporting_age_group rag ON rag.report_group_name = 'All Ages'
  LEFT OUTER JOIN (
                    SELECT
                      o1.person_id,
                      cn2.concept_id  AS answer,
                      cn1.concept_id  AS question,
                      v1.visit_id     AS visit_id,
                      v1.date_stopped AS datetime
                    FROM obs o1
                      INNER JOIN concept_name cn1
                        ON o1.concept_id = cn1.concept_id AND
                           cn1.concept_name_type = 'FULLY_SPECIFIED' AND cn1.name = 'Non Communicable Disease Set, Non Communicable Disease'
                           AND o1.voided = 0 AND cn1.voided = 0
                      INNER JOIN concept_name cn2
                        ON o1.value_coded = cn2.concept_id
                           AND cn2.concept_name_type = 'FULLY_SPECIFIED'
                           AND cn2.voided = 0
                      INNER JOIN encounter e1
                        ON o1.encounter_id = e1.encounter_id
                      INNER JOIN visit v1
                        ON v1.visit_id = e1.visit_id
                           AND v1.date_stopped IS NOT NULL
                    WHERE cast(v1.date_stopped AS DATE) BETWEEN '2014-10-01' AND '2015-11-11'
                          AND o1.obs_id = (SELECT max(obs_id)
                                           FROM obs obs2
                                             INNER JOIN encounter e2 ON obs2.encounter_id = e2.encounter_id
                                           WHERE obs2.concept_id = o1.concept_id
                                                 AND e2.visit_id = v1.visit_id
                                                 AND obs2.voided IS FALSE)
                  ) first_concept
    ON first_concept.answer = first_answers.answer
  LEFT  JOIN (
                    SELECT
                      o1.person_id,
                      cn2.concept_id  AS answer,
                      cn1.concept_id  AS question,
                      v1.visit_id     AS visit_id,
                      v1.date_stopped AS datetime,
                      e1.encounter_id
                    FROM obs o1
                      INNER JOIN concept_name cn1
                        ON o1.concept_id = cn1.concept_id AND
                           cn1.concept_name_type = 'FULLY_SPECIFIED' AND cn1.name = 'Non Communicable Disease Set, Risky Behaviour'
                           AND o1.voided = 0 AND cn1.voided = 0
                      INNER JOIN concept_name cn2
                        ON o1.value_coded = cn2.concept_id
                           AND cn2.concept_name_type = 'FULLY_SPECIFIED'
                           AND cn2.voided = 0
                      INNER JOIN encounter e1
                        ON o1.encounter_id = e1.encounter_id
                      INNER JOIN visit v1
                        ON v1.visit_id = e1.visit_id
                           AND v1.date_stopped IS NOT NULL
                    WHERE cast(v1.date_stopped AS DATE) BETWEEN '2014-10-01' AND '2015-11-11'
                          AND o1.obs_id = (SELECT max(obs_id)
                                           FROM obs obs2
                                             INNER JOIN encounter e2 ON obs2.encounter_id = e2.encounter_id
                                           WHERE obs2.concept_id = o1.concept_id
                                                 AND e2.visit_id = v1.visit_id
                                                 AND obs2.voided IS FALSE)
                  ) second_concept
    ON second_concept.answer = second_answers.answer
       AND first_concept.person_id = second_concept.person_id
       AND first_concept.visit_id = second_concept.visit_id
  LEFT OUTER JOIN person p ON first_concept.person_id = p.person_id AND p.gender = gender.gender
                              AND cast(first_concept.datetime AS DATE) BETWEEN (DATE_ADD(
    DATE_ADD(p.birthdate, INTERVAL rag.min_years YEAR), INTERVAL rag.min_days
    DAY)) AND (DATE_ADD(DATE_ADD(p.birthdate, INTERVAL rag.max_years YEAR), INTERVAL
                        rag.max_days DAY))
GROUP BY first_answers.answer_name, second_answers.answer_name, gender.gender, rag.name, rag.sort_order,p.person_id