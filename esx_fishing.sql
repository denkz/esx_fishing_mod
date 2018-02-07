USE `essentialmode`;

CREATE TABLE `fishes` (
  `id` int(11) NOT NULL,
  `owner_identifier` varchar(50) NOT NULL,
  `weight` float NOT NULL,
  `name` varchar(50) NOT NULL,
  `sex` varchar(50) NOT NULL,
  `hooked_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `fishes`
ADD PRIMARY KEY (`id`);

ALTER TABLE `fishes`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;
COMMIT;

INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES
('Fishing Rod', 'fishing rod', 1, 0, 1),
('Fishing Lure', 'fishing lure', -1, 0, 1),
('Small Pike', 'small pike', 20, 0, 1),
('Small Bass', 'small bass', 40, 0, 1),
('Small Salmon', 'small salmon', 20, 0, 1),
('Pike', 'pike', 10, 0, 1),
('Bass', 'bass', 20, 0, 1),
('Salmon', 'salmon', 10, 0, 1),
('Big Pike', 'big pike', 5, 0, 1),
('Big Bass', 'big bass', 10, 0, 1),
('Big Salmon', 'big salmon', 5, 0, 1);